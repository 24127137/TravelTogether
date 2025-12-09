from typing import Dict, List
from fastapi import WebSocket

class ConnectionManager:
    """
    Class quản lý các kết nối WebSocket.
    Lưu trữ theo dạng: { group_id: [list_of_sockets] }
    """
    def __init__(self):
        # Dictionary để lưu danh sách socket theo từng Group
        # Key: Group ID (int), Value: List các WebSocket đang kết nối
        self.active_connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, group_id: int):
        """Chấp nhận kết nối và lưu vào danh sách"""
        await websocket.accept()
        if group_id not in self.active_connections:
            self.active_connections[group_id] = []
        self.active_connections[group_id].append(websocket)
        print(f"Socket đã kết nối vào Group {group_id}. Tổng: {len(self.active_connections[group_id])}")

    def disconnect(self, websocket: WebSocket, group_id: int):
        """Ngắt kết nối và xóa khỏi danh sách"""
        if group_id in self.active_connections:
            if websocket in self.active_connections[group_id]:
                self.active_connections[group_id].remove(websocket)
                print(f"Socket đã rời Group {group_id}.")
            
            # Nếu nhóm trống thì xóa key luôn cho nhẹ RAM
            if len(self.active_connections[group_id]) == 0:
                del self.active_connections[group_id]

    async def broadcast(self, message: dict, group_id: int):
        """Gửi tin nhắn JSON tới TẤT CẢ thành viên trong nhóm"""
        if group_id in self.active_connections:
            for connection in self.active_connections[group_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    print(f"Lỗi gửi socket: {e}")
                    # Có thể socket đã chết nhưng chưa kịp disconnect
                    pass

# Tạo một instance duy nhất để dùng chung
manager = ConnectionManager()