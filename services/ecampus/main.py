from __future__ import annotations

import hmac
import os
from datetime import date, datetime, timedelta, timezone

from fastapi import FastAPI, Header, HTTPException, Query
from supabase import Client, create_client

from scraper import PortalAuthenticationError, PortalFormatError, fetch_academic_snapshot


app = FastAPI(title="PSGMX Academic Sync", version="2.0.0")
_client: Client | None = None


def database() -> Client:
    global _client
    if _client is None:
        url = os.environ.get("SUPABASE_URL", "")
        key = os.environ.get("SUPABASE_SERVICE_KEY", "")
        if not url or not key:
            raise HTTPException(status_code=503, detail="Database is not configured")
        _client = create_client(url, key)
    return _client


def authorize(value: str | None) -> None:
    expected = os.environ.get("API_SECRET", "")
    if not expected or not value or not hmac.compare_digest(value, expected):
        raise HTTPException(status_code=401, detail="Invalid service credential")


def password_for(rollno: str) -> str:
    sb = database()
    custom = sb.rpc("get_ecampus_password", {"p_reg_no": rollno}).execute().data
    if isinstance(custom, str) and custom.strip():
        return custom.strip()

    row = sb.table("users").select("dob").eq("reg_no", rollno).maybe_single().execute().data
    if not row or not row.get("dob"):
        row = sb.table("whitelist").select("dob").eq("reg_no", rollno).maybe_single().execute().data
    if not row or not row.get("dob"):
        raise HTTPException(status_code=422, detail="No eCampus credential is configured")
    dob = date.fromisoformat(str(row["dob"])[:10])
    return f"{dob.day:02d}{dob.strftime('%b').lower()}{dob.strftime('%y')}"


@app.get("/health")
def health():
    return {"ok": True, "service": "attendance-and-weekly-timetable"}


@app.post("/api/ecampus/sync")
def sync(
    rollno: str = Query(pattern=r"^\d{2}MX\d{3}$"),
    x_api_secret: str | None = Header(default=None),
):
    authorize(x_api_secret)
    rollno = rollno.upper()
    try:
        snapshot = fetch_academic_snapshot(rollno, password_for(rollno))
    except PortalAuthenticationError as error:
        raise HTTPException(status_code=422, detail="eCampus rejected the saved credential") from error
    except (PortalFormatError, OSError) as error:
        raise HTTPException(status_code=502, detail="eCampus response format changed or is unavailable") from error

    now = datetime.now(timezone.utc).isoformat()
    week_start = (datetime.now(timezone.utc).date() - timedelta(days=datetime.now(timezone.utc).weekday())).isoformat()
    sb = database()
    sb.table("ecampus_attendance").upsert(
        {"reg_no": rollno, "data": snapshot.attendance, "synced_at": now},
        on_conflict="reg_no",
    ).execute()
    sb.table("ecampus_weekly_timetable").upsert(
        {"reg_no": rollno, "week_start": week_start, "data": snapshot.timetable, "synced_at": now},
        on_conflict="reg_no",
    ).execute()
    return {
        "ok": True,
        "attendance_subjects": len(snapshot.attendance["subjects"]),
        "timetable_rows": len(snapshot.timetable["rows"]),
        "synced_at": now,
    }
