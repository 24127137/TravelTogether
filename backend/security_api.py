"""
security_api.py
FastAPI routes for security system
"""

from fastapi import APIRouter, HTTPException, Header, BackgroundTasks
from typing import Optional
from datetime import datetime
from supabase import create_client

from security_model import (
    RegisterPinRequest,
    VerifyPinRequest,
    ResetPinRequest,
    HeartbeatRequest,
    GenericResponse,
    StatusResponse,
    InternalJobResponse,
    PinVerifyResult
)

import security_service as service
from config import settings

# ==================== CONFIGURATION ====================

router = APIRouter(prefix="/api/security", tags=["security"])

# Admin và Cron tokens - thêm vào config.py
ADMIN_TOKEN = settings.ADMIN_TOKEN
INTERNAL_CRON_TOKEN = settings.INTERNAL_CRON_TOKEN


# ==================== HELPER FUNCTIONS ====================

def verify_admin_token(token: str) -> bool:
    """Verify admin authentication"""
    return token == ADMIN_TOKEN


def verify_cron_token(token: str) -> bool:
    """Verify internal cron job authentication"""
    return token == INTERNAL_CRON_TOKEN


async def send_danger_alert(user_id: str, reason: str):
    """
    Background task to send danger alert
    This should integrate with your email/SMS service
    """
    try:
        print(f"🚨 DANGER ALERT for user {user_id}: {reason}")
        
        # TODO: Integrate with email service (SendGrid, AWS SES, etc.)
        # TODO: Fetch emergency contacts from database
        # TODO: Send emails/SMS to emergency contacts
        
        # Log the alert
        supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        
        supabase.table("alert_logs").insert({
            "user_id": user_id,
            "alert_type": "DANGER",
            "reason": reason,
            "timestamp": datetime.utcnow().isoformat(),
            "status": "sent"
        }).execute()
        
    except Exception as e:
        print(f"Error sending danger alert: {e}")


async def send_reminder_notification(user_id: str):
    """
    Background task to send reminder notification
    """
    try:
        print(f"📢 REMINDER for user {user_id}")
        
        # TODO: Integrate with push notification service (Firebase, OneSignal, etc.)
        
        # Log the notification
        supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        
        supabase.table("notification_logs").insert({
            "user_id": user_id,
            "notification_type": "REMINDER",
            "timestamp": datetime.utcnow().isoformat(),
            "status": "sent"
        }).execute()
        
    except Exception as e:
        print(f"Error sending reminder: {e}")


# ==================== PUBLIC ENDPOINTS ====================

@router.post("/register_pin", response_model=GenericResponse)
async def register_pin(request: RegisterPinRequest):
    """
    Register new user with safe and danger PINs
    
    This is the initial setup endpoint where users create their security PINs.
    """
    try:
        success, message = service.register_pin(
            user_id=request.user_id,
            safe_pin=request.safe_pin,
            danger_pin=request.danger_pin,
            default_confirmation_time=request.default_confirmation_time
        )
        
        return GenericResponse(
            success=success,
            message=message
        )
    
    except Exception as e:
        return GenericResponse(
            success=False,
            message=f"Registration error: {str(e)}"
        )


@router.post("/verify_pin", response_model=GenericResponse)
async def verify_pin(request: VerifyPinRequest, background_tasks: BackgroundTasks):
    """
    Verify user PIN input
    
    CRITICAL: Always returns success=True to prevent attackers from knowing
    which PIN type was entered. The actual alert is triggered in background.
    """
    try:
        result_code, message = service.verify_pin(
            user_id=request.user_id,
            pin=request.pin
        )
        
        # Handle SAFE PIN
        if result_code == PinVerifyResult.SAFE:
            return GenericResponse(
                success=True,
                message="Confirmation successful"
            )
        
        # Handle DANGER PIN - silent alert
        if result_code == PinVerifyResult.DANGER:
            # Trigger background alert
            background_tasks.add_task(
                send_danger_alert,
                user_id=request.user_id,
                reason="danger_pin_used"
            )
            
            # Return same response as safe PIN
            return GenericResponse(
                success=True,
                message="Confirmation successful"
            )
        
        # Handle LOCKED account
        if result_code == PinVerifyResult.LOCKED:
            # Trigger danger alert for locked account
            background_tasks.add_task(
                send_danger_alert,
                user_id=request.user_id,
                reason="account_locked_max_retry"
            )
            
            return GenericResponse(
                success=False,
                message="Account is locked. Please contact support."
            )
        
        # Handle WRONG PIN
        if result_code == PinVerifyResult.WRONG_PIN:
            return GenericResponse(
                success=False,
                message=message  # Contains retry count info
            )
        
        # Fallback
        return GenericResponse(
            success=False,
            message="Verification failed"
        )
    
    except Exception as e:
        print(f"Error in verify_pin endpoint: {e}")
        return GenericResponse(
            success=False,
            message="Verification error occurred"
        )


@router.post("/reset_pin", response_model=GenericResponse)
async def reset_pin(request: ResetPinRequest):
    """
    Reset user PINs (admin only)
    
    This endpoint requires admin authentication.
    """
    try:
        # Verify admin token
        if not verify_admin_token(request.admin_token):
            raise HTTPException(status_code=403, detail="Invalid admin token")
        
        success, message = service.reset_pin(
            user_id=request.user_id,
            new_safe_pin=request.new_safe_pin,
            new_danger_pin=request.new_danger_pin
        )
        
        return GenericResponse(
            success=success,
            message=message
        )
    
    except HTTPException:
        raise
    except Exception as e:
        return GenericResponse(
            success=False,
            message=f"Reset error: {str(e)}"
        )


@router.post("/heartbeat", response_model=GenericResponse)
async def heartbeat(request: HeartbeatRequest):
    """
    Update user's last online timestamp
    
    Client apps should call this endpoint every 30-60 minutes
    to maintain "online" status.
    """
    try:
        success, message = service.update_heartbeat(
            user_id=request.user_id,
            device_info=request.device_info
        )
        
        return GenericResponse(
            success=success,
            message=message
        )
    
    except Exception as e:
        return GenericResponse(
            success=False,
            message=f"Heartbeat error: {str(e)}"
        )


@router.get("/status", response_model=StatusResponse)
async def get_status(user_id: str):
    """
    Get current security status for user
    
    Returns comprehensive status information for client display.
    """
    try:
        status_data = service.get_status(user_id)
        return StatusResponse(**status_data)
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching status: {str(e)}"
        )


# ==================== INTERNAL CRON JOB ENDPOINTS ====================

@router.post("/internal/check_reminder", response_model=InternalJobResponse)
async def check_reminder(
    background_tasks: BackgroundTasks,
    x_cron_token: Optional[str] = Header(None)
):
    """
    Cron job to check users who need reminders (24h mark)
    
    Should be called every hour by a cron scheduler.
    Requires internal authentication token.
    """
    try:
        # Verify cron token
        if not verify_cron_token(x_cron_token):
            raise HTTPException(status_code=403, detail="Invalid cron token")
        
        users_need_reminder = service.check_users_need_reminder()
        
        # Send notifications in background
        for user in users_need_reminder:
            background_tasks.add_task(
                send_reminder_notification,
                user_id=user["user_id"]
            )
        
        return InternalJobResponse(
            success=True,
            processed_count=len(users_need_reminder),
            details=users_need_reminder
        )
    
    except HTTPException:
        raise
    except Exception as e:
        return InternalJobResponse(
            success=False,
            processed_count=0,
            details=[{"error": str(e)}]
        )


@router.post("/internal/check_danger", response_model=InternalJobResponse)
async def check_danger(
    background_tasks: BackgroundTasks,
    x_cron_token: Optional[str] = Header(None)
):
    """
    Cron job to check users in danger state (36h+ no confirmation)
    
    Should be called every hour by a cron scheduler.
    Sends alerts to emergency contacts.
    """
    try:
        # Verify cron token
        if not verify_cron_token(x_cron_token):
            raise HTTPException(status_code=403, detail="Invalid cron token")
        
        users_in_danger = service.check_users_in_danger()
        
        # Send danger alerts in background
        for user in users_in_danger:
            background_tasks.add_task(
                send_danger_alert,
                user_id=user["user_id"],
                reason=", ".join(user["reasons"])
            )
        
        return InternalJobResponse(
            success=True,
            processed_count=len(users_in_danger),
            details=users_in_danger
        )
    
    except HTTPException:
        raise
    except Exception as e:
        return InternalJobResponse(
            success=False,
            processed_count=0,
            details=[{"error": str(e)}]
        )


# ==================== HEALTH CHECK ====================

@router.get("/health")
async def health_check():
    """Simple health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "security-api"
    }