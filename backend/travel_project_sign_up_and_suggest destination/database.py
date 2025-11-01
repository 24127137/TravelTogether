from sqlmodel import create_engine, Session
from typing import Generator
from config import settings # <-- Đọc "bí mật" từ config

# Tạo engine bằng cách đọc DATABASE_URL từ file config
engine = create_engine(
    settings.DATABASE_URL, 
    echo=True, # echo=True để xem log SQL trong terminal
    connect_args={"sslmode": "require"}
)

def get_session() -> Generator[Session, None, None]:
    """
    Dependency injector cho FastAPI
    Tạo một phiên (session) database mới cho mỗi request API.
    """
    with Session(engine) as session:
        try:
            yield session
        finally:
            session.close()