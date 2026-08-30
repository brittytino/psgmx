"""Small eCampus adapter derived from the user-provided attendance/timetable script.

Only academic attendance and the weekly timetable are fetched. The adapter is
stateless: credentials and portal cookies never leave the current request.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import requests
from bs4 import BeautifulSoup


NEW_PORTAL = "https://ecampus.psgtech.ac.in/studzone"
OLD_PORTAL = "https://ecampus.psgtech.ac.in/studzone2/"
ATTENDANCE_URL = f"{NEW_PORTAL}/Attendance/StudentPercentage"
TIMETABLE_URL = f"{OLD_PORTAL}AttWfStudTimtab.aspx"
TIMEOUT = (10, 25)
HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; PSGMX-Academic-Sync/1.0)",
    "Origin": "https://ecampus.psgtech.ac.in",
}


class PortalAuthenticationError(RuntimeError):
    pass


class PortalFormatError(RuntimeError):
    pass


@dataclass(frozen=True)
class AcademicSnapshot:
    attendance: dict
    timetable: dict


def _hidden(soup: BeautifulSoup, selector: str) -> str:
    element = soup.select_one(selector)
    return str(element.get("value", "")) if element else ""


def _new_portal_login(rollno: str, password: str) -> requests.Session:
    session = requests.Session()
    page = session.get(f"{NEW_PORTAL}/", headers=HEADERS, timeout=TIMEOUT)
    page.raise_for_status()
    soup = BeautifulSoup(page.text, "html.parser")
    token = soup.find("input", {"name": "__RequestVerificationToken"})
    response = session.post(
        NEW_PORTAL,
        data={
            "rollno": rollno,
            "password": password,
            "chkterms": "on",
            "__RequestVerificationToken": token.get("value", "") if token else "",
        },
        headers={**HEADERS, "Referer": f"{NEW_PORTAL}/"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    response.raise_for_status()
    result = BeautifulSoup(response.text, "html.parser")
    if result.find("input", {"id": "rollno"}) and result.find("input", {"id": "password"}):
        raise PortalAuthenticationError("eCampus rejected the credentials")
    return session


def _old_portal_login(rollno: str, password: str) -> requests.Session:
    session = requests.Session()
    page = session.get(OLD_PORTAL, headers=HEADERS, timeout=TIMEOUT)
    page.raise_for_status()
    soup = BeautifulSoup(page.text, "html.parser")
    response = session.post(
        OLD_PORTAL,
        data={
            "__VIEWSTATE": _hidden(soup, "#__VIEWSTATE"),
            "__VIEWSTATEGENERATOR": _hidden(soup, "#__VIEWSTATEGENERATOR"),
            "__EVENTVALIDATION": _hidden(soup, "#__EVENTVALIDATION"),
            "txtusercheck": rollno,
            "txtpwdcheck": password,
            "abcd3": "Login",
        },
        headers=HEADERS,
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    response.raise_for_status()
    return session


def _course_map(session: requests.Session) -> dict[str, str]:
    page = session.get(TIMETABLE_URL, headers=HEADERS, timeout=TIMEOUT)
    page.raise_for_status()
    soup = BeautifulSoup(page.text, "html.parser")
    table = soup.find("table", {"id": "TbCourDesc"})
    if not table:
        return {}
    mapping = {}
    for row in table.find_all("tr")[1:]:
        values = [cell.get_text(" ", strip=True) for cell in row.find_all("td")]
        if len(values) >= 2 and values[0]:
            mapping[values[0]] = values[1]
    return mapping


def _attendance(session: requests.Session, courses: dict[str, str]) -> dict:
    page = session.get(ATTENDANCE_URL, headers=HEADERS, timeout=TIMEOUT)
    page.raise_for_status()
    soup = BeautifulSoup(page.text, "html.parser")
    table = soup.find("table", {"class": "table"})
    if not table:
        table = next((item for item in soup.find_all("table") if "attendance" in item.get_text(" ", strip=True).lower()), None)
    if not table:
        raise PortalFormatError("attendance table not found")

    subjects = []
    body = table.find("tbody") or table
    for row in body.find_all("tr"):
        values = [cell.get_text(" ", strip=True) for cell in row.find_all("td")]
        if len(values) < 8:
            continue
        try:
            code = values[0]
            total = int(values[1])
            exception = int(values[2] or 0)
            present = int(values[4])
            percentage = float(values[5])
        except (ValueError, IndexError):
            continue
        need = math.ceil((0.75 * total - present) / 0.25) if percentage < 75 else 0
        can_bunk = math.floor((present - 0.75 * total) / 0.75) if percentage >= 75 else 0
        subjects.append({
            "course_code": code,
            "course_title": courses.get(code, code),
            "total_hours": total,
            "exception_hour": exception,
            "total_present": present,
            "percentage": round(percentage, 2),
            "classes_to_attend": max(0, need),
            "can_bunk": max(0, can_bunk),
            "attendance_from": values[8] if len(values) > 8 else "",
            "attendance_to": values[9] if len(values) > 9 else "",
        })
    if not subjects:
        raise PortalFormatError("attendance rows not found")

    total_hours = sum(item["total_hours"] for item in subjects)
    total_present = sum(item["total_present"] for item in subjects)
    percentage = round(total_present * 100 / total_hours, 2) if total_hours else 0
    need = math.ceil((0.75 * total_hours - total_present) / 0.25) if percentage < 75 else 0
    can_bunk = math.floor((total_present - 0.75 * total_hours) / 0.75) if percentage >= 75 else 0
    return {
        "subjects": subjects,
        "summary": {
            "total_hours": total_hours,
            "total_present": total_present,
            "overall_percentage": percentage,
            "overall_can_bunk": max(0, can_bunk),
            "overall_need_attend": max(0, need),
        },
    }


def _weekly_timetable(session: requests.Session) -> dict:
    page = session.get(TIMETABLE_URL, headers=HEADERS, timeout=TIMEOUT)
    page.raise_for_status()
    soup = BeautifulSoup(page.text, "html.parser")
    selected = None
    for table in soup.find_all("table"):
        if table.get("id") == "TbCourDesc":
            continue
        content = table.get_text(" ", strip=True).upper()
        if sum(day in content for day in ("MON", "TUE", "WED", "THU", "FRI")) >= 3:
            selected = table
            break
    if not selected:
        return {"headers": [], "rows": []}

    rows = []
    for row in selected.find_all("tr"):
        values = [cell.get_text(" ", strip=True) for cell in row.find_all(["th", "td"])]
        if any(values) and not (len(values) == 1 and values[0].isdigit()):
            rows.append(values)
    if not rows:
        return {"headers": [], "rows": []}
    headers = rows[0]
    normalized = [(row + [""] * len(headers))[:len(headers)] for row in rows[1:] if len(row) >= 2]
    return {"headers": headers, "rows": normalized}


def fetch_academic_snapshot(rollno: str, password: str) -> AcademicSnapshot:
    new_session = _new_portal_login(rollno, password)
    old_session = _old_portal_login(rollno, password)
    courses = _course_map(old_session)
    return AcademicSnapshot(
        attendance=_attendance(new_session, courses),
        timetable=_weekly_timetable(old_session),
    )
