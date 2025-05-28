from pydantic import BaseModel, EmailStr, Field

class UserCreate(BaseModel): #curl -X POST http://127.0.0.1:8000/user -H "Content-Type: application/json" -d '{"name": "Stefano Sbarbaro", "email": "s.sbarbaro@prima.it"}'
    name: str = Field(..., min_length=3, max_length=50, pattern=r'^[a-zA-Z ]+$')
    email: EmailStr

    class Config:
        anystr_strip_whitespace = True

class UserOut(UserCreate): #curl http://127.0.0.1:8000/users
    id: int
