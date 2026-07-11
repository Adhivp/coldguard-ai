from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import models
import schemas
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="ColdGuard API")


@app.post("/readings", response_model=schemas.SensorReadingOut, status_code=201)
def create_reading(reading: schemas.SensorReadingCreate, db: Session = Depends(get_db)):
    db_reading = models.SensorReading(**reading.model_dump())
    db.add(db_reading)
    db.commit()
    db.refresh(db_reading)
    return db_reading


@app.get("/readings", response_model=List[schemas.SensorReadingOut])
def get_readings(device_id: str = None, limit: int = 100, db: Session = Depends(get_db)):
    query = db.query(models.SensorReading)
    if device_id:
        query = query.filter(models.SensorReading.device_id == device_id)
    return query.order_by(models.SensorReading.timestamp.desc()).limit(limit).all()


@app.get("/readings/latest", response_model=schemas.SensorReadingOut)
def get_latest(device_id: str, db: Session = Depends(get_db)):
    reading = (
        db.query(models.SensorReading)
        .filter(models.SensorReading.device_id == device_id)
        .order_by(models.SensorReading.timestamp.desc())
        .first()
    )
    if not reading:
        raise HTTPException(status_code=404, detail="No readings found for this device")
    return reading


@app.delete("/readings/{reading_id}", status_code=204)
def delete_reading(reading_id: int, db: Session = Depends(get_db)):
    reading = db.query(models.SensorReading).filter(models.SensorReading.id == reading_id).first()
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    db.delete(reading)
    db.commit()
