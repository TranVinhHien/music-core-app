from enum import Enum
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
import datetime

class TaskStatus(str, Enum):
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    SKIPPED = "SKIPPED"

class ChecklistTask(BaseModel):
    id: str
    index: int
    title: str
    category: str = "General"
    description: str = ""
    intent_type: str = "CURATED_BATCH"  # ALBUM, ARTIST_TOP, CURATED_BATCH, GENRE_BATCH
    target_count: int = 1
    crawled_count: int = 0
    status: TaskStatus = TaskStatus.PENDING
    query_hints: List[str] = Field(default_factory=list)
    album_name: Optional[str] = None
    artist_name: Optional[str] = None
    completed_tracks: List[Dict[str, Any]] = Field(default_factory=list)
    errors: List[str] = Field(default_factory=list)

class TrackExecutionResult(BaseModel):
    title: str
    artist: str
    album: Optional[str] = None
    file_url: Optional[str] = None
    catalog_id: Optional[str] = None
    parsed_artists: List[Dict[str, Any]] = Field(default_factory=list)
    audio_analysis: Optional[Dict[str, Any]] = None
    size_mb: Optional[float] = None
    attempts_used: int = 1
    success: bool = True
    error_message: Optional[str] = None

class HermesPlan(BaseModel):
    plan_id: str
    goal: str
    user_prompt: str
    total_target_count: int
    total_crawled_count: int = 0
    status: str = "IN_PROGRESS"  # IN_PROGRESS, COMPLETED, PARTIALLY_COMPLETED, FAILED
    tasks: List[ChecklistTask] = Field(default_factory=list)
    created_at: str = Field(default_factory=lambda: datetime.datetime.now().isoformat())
    updated_at: str = Field(default_factory=lambda: datetime.datetime.now().isoformat())

