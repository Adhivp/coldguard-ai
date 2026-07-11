from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class SensorReadingCreate(BaseModel):
    device_id: str
    temperature: float
    humidity: Optional[float] = None


class SensorReadingOut(SensorReadingCreate):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True
