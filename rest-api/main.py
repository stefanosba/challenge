from fastapi import FastAPI, HTTPException
from db import init_db
from schemas import UserCreate, UserOut
from crud import get_users, create_user

app = FastAPI()
init_db()

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/favicon.ico")
def favicon():
    return {}

@app.get("/users", response_model=list[UserOut])
def read_users():
    users = get_users()
    return [UserOut(id=u[0], name=u[1], email=u[2]) for u in users]

@app.post("/user", response_model=UserOut)
def add_user(user: UserCreate):
    try:
        user_id = create_user(user.name, user.email)
        return UserOut(id=user_id, **user.dict())
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except:
        raise HTTPException(status_code=500, detail="An unexpected error occurred")
