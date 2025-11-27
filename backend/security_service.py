"""
security_service.py
Business logic layer for security operations
"""

import hashlib
from datetime import datetime, timedelta
from typing import Optional, List, Tuple
from supabase import create_client, Client
from security_model import UserSecurityData, PinVerifyResult
from config import settings

# ==================== CONFIGURATION ====================

supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

# Security thresholds
REMINDER_HOURS = 24
DANGER_HOURS = 36
MAX_RETRY_ATTEMPTS = 5


# ==================== HELPER FUNCTIONS ====================

def hash_pin(pin: str) -> str:
    """Hash PIN using SHA256"""
    return hashlib.sha256(pin.encode()).hexdigest()


def calculate_next_confirmation_time(default_time: str, last_confirmation: Optional[datetime]) -> datetime:
    """
    Calculate next required confirmation time
    default_time format: "HH:MM" (e.g., "22:00")
    """
    now = datetime.now(datetime.timezone.utc)
    
    if not last_confirmation:
        # First time - use today's default time
        hour, minute = map(int, default_time.split(':'))
        next_time = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
        if next_time < now:
            next_time += timedelta(days=1)
        return next_time
    
    # Calculate based on last confirmation
    hour, minute = map(int, default_time.split(':'))
    next_time = last_confirmation.replace(hour=hour, minute=minute, second=0, microsecond=0)
    next_time += timedelta(days=1)
    
    return next_time


def get_user_security_data(user_id: str) -> Optional[UserSecurityData]:
    """Fetch user security data from database"""
    try:
        response = supabase.table("user_security").select("*").eq("user_id", user_id).single().execute()
        if response.data:
            return UserSecurityData(**response.data)
        return None
    except Exception as e:
        print(f"Error fetching user data: {e}")
        return None


# ==================== PUBLIC SERVICE FUNCTIONS ====================

def register_pin(
    user_id: str,
    safe_pin: str,
    danger_pin: str,
    default_confirmation_time: str
) -> Tuple[bool, str]:
    """
    Register new user with safe and danger PINs
    Returns: (success, message)
    """
    try:
        # Check if user already exists
        existing = get_user_security_data(user_id)
        if existing:
            return False, "User already registered"
        
        # Hash PINs
        safe_hash = hash_pin(safe_pin)
        danger_hash = hash_pin(danger_pin)
        
        # Insert into database
        now = datetime.utcnow()
        data = {
            "user_id": user_id,
            "safe_pin_hash": safe_hash,
            "danger_pin_hash": danger_hash,
            "default_confirmation_time": default_confirmation_time,
            "last_confirmation_ts": now.isoformat(),
            "last_online_ts": now.isoformat(),
            "retry_fail_count": 0,
            "is_locked": False,
            "created_at": now.isoformat(),
            "updated_at": now.isoformat()
        }
        
        supabase.table("user_security").insert(data).execute()
        
        return True, "Registration successful"
    
    except Exception as e:
        print(f"Error in register_pin: {e}")
        return False, f"Registration failed: {str(e)}"


def verify_pin(user_id: str, pin: str) -> Tuple[str, str]:
    """
    Verify PIN input from user
    Returns: (result_code, message)
    result_code: SAFE | DANGER | WRONG_PIN | LOCKED
    """
    try:
        user_data = get_user_security_data(user_id)
        
        if not user_data:
            return PinVerifyResult.WRONG_PIN, "User not found"
        
        # Check if account is locked
        if user_data.is_locked:
            return PinVerifyResult.LOCKED, "Account is locked"
        
        # Hash input PIN
        input_hash = hash_pin(pin)
        
        # Check SAFE PIN
        if input_hash == user_data.safe_pin_hash:
            # Update confirmation timestamp and reset retry count
            now = datetime.utcnow()
            supabase.table("user_security").update({
                "last_confirmation_ts": now.isoformat(),
                "last_online_ts": now.isoformat(),
                "retry_fail_count": 0,
                "updated_at": now.isoformat()
            }).eq("user_id", user_id).execute()
            
            return PinVerifyResult.SAFE, "Confirmation successful"
        
        # Check DANGER PIN
        if input_hash == user_data.danger_pin_hash:
            # Update online time but NOT confirmation time
            now = datetime.utcnow()
            supabase.table("user_security").update({
                "last_online_ts": now.isoformat(),
                "updated_at": now.isoformat()
            }).eq("user_id", user_id).execute()
            
            # Log danger event
            supabase.table("security_events").insert({
                "user_id": user_id,
                "event_type": "DANGER_PIN_USED",
                "timestamp": now.isoformat(),
                "details": {"source": "pin_verification"}
            }).execute()
            
            return PinVerifyResult.DANGER, "Alert triggered"
        
        # WRONG PIN - increment retry count
        new_retry_count = user_data.retry_fail_count + 1
        update_data = {
            "retry_fail_count": new_retry_count,
            "last_online_ts": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }
        
        # Lock account if too many failures
        if new_retry_count > MAX_RETRY_ATTEMPTS:
            update_data["is_locked"] = True
            supabase.table("user_security").update(update_data).eq("user_id", user_id).execute()
            
            # Log lock event
            supabase.table("security_events").insert({
                "user_id": user_id,
                "event_type": "ACCOUNT_LOCKED",
                "timestamp": datetime.utcnow().isoformat(),
                "details": {"reason": "max_retry_exceeded", "attempts": new_retry_count}
            }).execute()
            
            return PinVerifyResult.LOCKED, "Account locked due to multiple failed attempts"
        
        supabase.table("user_security").update(update_data).eq("user_id", user_id).execute()
        
        return PinVerifyResult.WRONG_PIN, f"Wrong PIN. {MAX_RETRY_ATTEMPTS - new_retry_count} attempts remaining"
    
    except Exception as e:
        print(f"Error in verify_pin: {e}")
        return PinVerifyResult.WRONG_PIN, "Verification failed"


def reset_pin(
    user_id: str,
    new_safe_pin: Optional[str] = None,
    new_danger_pin: Optional[str] = None
) -> Tuple[bool, str]:
    """
    Reset user PINs (admin function)
    """
    try:
        user_data = get_user_security_data(user_id)
        if not user_data:
            return False, "User not found"
        
        update_data = {
            "updated_at": datetime.utcnow().isoformat(),
            "retry_fail_count": 0,
            "is_locked": False
        }
        
        if new_safe_pin:
            update_data["safe_pin_hash"] = hash_pin(new_safe_pin)
        
        if new_danger_pin:
            update_data["danger_pin_hash"] = hash_pin(new_danger_pin)
        
        supabase.table("user_security").update(update_data).eq("user_id", user_id).execute()
        
        # Log reset event
        supabase.table("security_events").insert({
            "user_id": user_id,
            "event_type": "PIN_RESET",
            "timestamp": datetime.utcnow().isoformat(),
            "details": {
                "safe_pin_changed": new_safe_pin is not None,
                "danger_pin_changed": new_danger_pin is not None
            }
        }).execute()
        
        return True, "PIN reset successful"
    
    except Exception as e:
        print(f"Error in reset_pin: {e}")
        return False, f"Reset failed: {str(e)}"


def update_heartbeat(user_id: str, device_info: Optional[str] = None) -> Tuple[bool, str]:
    """
    Update user's last online timestamp
    """
    try:
        now = datetime.utcnow()
        update_data = {
            "last_online_ts": now.isoformat(),
            "updated_at": now.isoformat()
        }
        
        supabase.table("user_security").update(update_data).eq("user_id", user_id).execute()
        
        # Optional: log heartbeat with device info
        if device_info:
            supabase.table("heartbeat_logs").insert({
                "user_id": user_id,
                "timestamp": now.isoformat(),
                "device_info": device_info
            }).execute()
        
        return True, "Heartbeat updated"
    
    except Exception as e:
        print(f"Error in update_heartbeat: {e}")
        return False, "Heartbeat update failed"


def get_status(user_id: str) -> dict:
    """
    Get current security status for user
    """
    try:
        user_data = get_user_security_data(user_id)
        
        if not user_data:
            return {
                "last_confirmation_ts": None,
                "last_online_ts": None,
                "next_required_time": None,
                "state": "locked",
                "hours_since_confirmation": None,
                "hours_since_online": None
            }
        
        now = datetime.utcnow()
        
        # Calculate hours since last confirmation
        hours_since_confirmation = None
        if user_data.last_confirmation_ts:
            delta = now - user_data.last_confirmation_ts
            hours_since_confirmation = delta.total_seconds() / 3600
        
        # Calculate hours since last online
        hours_since_online = None
        if user_data.last_online_ts:
            delta = now - user_data.last_online_ts
            hours_since_online = delta.total_seconds() / 3600
        
        # Calculate next required confirmation time
        next_time = calculate_next_confirmation_time(
            user_data.default_confirmation_time,
            user_data.last_confirmation_ts
        )
        
        # Determine state
        state = "safe"
        if user_data.is_locked or user_data.retry_fail_count > MAX_RETRY_ATTEMPTS:
            state = "locked"
        elif hours_since_confirmation and hours_since_confirmation >= DANGER_HOURS:
            state = "danger_pending"
        elif hours_since_confirmation and hours_since_confirmation >= REMINDER_HOURS:
            state = "danger_pending"
        
        return {
            "last_confirmation_ts": user_data.last_confirmation_ts.isoformat() if user_data.last_confirmation_ts else None,
            "last_online_ts": user_data.last_online_ts.isoformat() if user_data.last_online_ts else None,
            "next_required_time": next_time.isoformat(),
            "state": state,
            "hours_since_confirmation": round(hours_since_confirmation, 2) if hours_since_confirmation else None,
            "hours_since_online": round(hours_since_online, 2) if hours_since_online else None
        }
    
    except Exception as e:
        print(f"Error in get_status: {e}")
        return {
            "last_confirmation_ts": None,
            "last_online_ts": None,
            "next_required_time": None,
            "state": "locked",
            "hours_since_confirmation": None,
            "hours_since_online": None
        }


# ==================== CRON JOB FUNCTIONS ====================

def check_users_need_reminder() -> List[dict]:
    """
    Find users who need reminder (24h+ since last confirmation)
    Returns list of users to send notifications
    """
    try:
        now = datetime.utcnow()
        reminder_threshold = now - timedelta(hours=REMINDER_HOURS)
        
        response = supabase.table("user_security").select("*").execute()
        
        users_need_reminder = []
        
        for record in response.data:
            user_data = UserSecurityData(**record)
            
            # Skip locked users
            if user_data.is_locked:
                continue
            
            # Check if reminder needed
            if user_data.last_confirmation_ts and user_data.last_confirmation_ts < reminder_threshold:
                hours_passed = (now - user_data.last_confirmation_ts).total_seconds() / 3600
                
                # Only send reminder once (between 24h-36h)
                if REMINDER_HOURS <= hours_passed < DANGER_HOURS:
                    users_need_reminder.append({
                        "user_id": user_data.user_id,
                        "hours_since_confirmation": round(hours_passed, 2),
                        "next_required_time": calculate_next_confirmation_time(
                            user_data.default_confirmation_time,
                            user_data.last_confirmation_ts
                        ).isoformat()
                    })
        
        return users_need_reminder
    
    except Exception as e:
        print(f"Error in check_users_need_reminder: {e}")
        return []


def check_users_in_danger() -> List[dict]:
    """
    Find users in danger state (36h+ no confirmation OR locked)
    Returns list of users to send alerts
    """
    try:
        now = datetime.utcnow()
        danger_threshold = now - timedelta(hours=DANGER_HOURS)
        
        response = supabase.table("user_security").select("*").execute()
        
        users_in_danger = []
        
        for record in response.data:
            user_data = UserSecurityData(**record)
            
            danger_reasons = []
            
            # Check 1: Account locked
            if user_data.is_locked or user_data.retry_fail_count > MAX_RETRY_ATTEMPTS:
                danger_reasons.append("account_locked")
            
            # Check 2: No confirmation for 36h+
            if user_data.last_confirmation_ts and user_data.last_confirmation_ts < danger_threshold:
                hours_passed = (now - user_data.last_confirmation_ts).total_seconds() / 3600
                danger_reasons.append(f"no_confirmation_{round(hours_passed, 1)}h")
            
            # Check 3: Not online for 36h+ (optional additional check)
            if user_data.last_online_ts and user_data.last_online_ts < danger_threshold:
                hours_passed = (now - user_data.last_online_ts).total_seconds() / 3600
                danger_reasons.append(f"offline_{round(hours_passed, 1)}h")
            
            if danger_reasons:
                users_in_danger.append({
                    "user_id": user_data.user_id,
                    "reasons": danger_reasons,
                    "last_confirmation": user_data.last_confirmation_ts.isoformat() if user_data.last_confirmation_ts else None,
                    "last_online": user_data.last_online_ts.isoformat() if user_data.last_online_ts else None
                })
                
                # Log danger event
                supabase.table("security_events").insert({
                    "user_id": user_data.user_id,
                    "event_type": "DANGER_STATE_DETECTED",
                    "timestamp": now.isoformat(),
                    "details": {"reasons": danger_reasons}
                }).execute()
        
        return users_in_danger
    
    except Exception as e:
        print(f"Error in check_users_in_danger: {e}")
        return []