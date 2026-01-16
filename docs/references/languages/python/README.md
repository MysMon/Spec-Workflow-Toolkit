
# Python Development

Comprehensive patterns and practices for Python development.

## Project Setup

### Modern pyproject.toml

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Project description"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.100.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-asyncio>=0.21.0",
    "ruff>=0.1.0",
    "mypy>=1.0.0",
]

[tool.ruff]
line-length = 88
target-version = "py311"
select = ["E", "F", "I", "N", "W", "UP"]

[tool.mypy]
python_version = "3.11"
strict = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

### Virtual Environments

```bash
# Create with venv
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Create with uv (faster)
uv venv
source .venv/bin/activate

# Install dependencies
pip install -e ".[dev]"
# or with uv
uv pip install -e ".[dev]"
```

## Type Hints

### Basic Types

```python
from typing import Optional, Union
from collections.abc import Sequence

# Variables
name: str = "John"
age: int = 30
scores: list[int] = [95, 87, 92]
metadata: dict[str, str] = {"key": "value"}

# Functions
def greet(name: str) -> str:
    return f"Hello, {name}"

def process(items: Sequence[int]) -> list[int]:
    return [x * 2 for x in items]

# Optional and Union
def find_user(id: str) -> Optional[User]:
    ...

def parse(value: str | int) -> str:  # Python 3.10+ union syntax
    ...
```

### Pydantic Models

```python
from pydantic import BaseModel, EmailStr, Field

class UserCreate(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    age: int | None = Field(default=None, ge=0, le=150)

class UserResponse(BaseModel):
    id: str
    email: str
    name: str

    model_config = {"from_attributes": True}
```

## Code Style

### Naming Conventions

```python
# Variables and functions: snake_case
user_name = "john"
def get_user_by_id(user_id: str) -> User:
    ...

# Classes: PascalCase
class UserService:
    ...

# Constants: SCREAMING_SNAKE_CASE
MAX_RETRIES = 3
API_BASE_URL = "/api/v1"

# Private: leading underscore
_internal_cache: dict[str, Any] = {}
def _helper_function() -> None:
    ...
```

### Import Organization

```python
# 1. Standard library
import os
from pathlib import Path
from typing import Optional

# 2. Third-party packages
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx

# 3. Local imports
from app.services import UserService
from app.models import User
from .utils import helper
```

## Error Handling

### Custom Exceptions

```python
class AppError(Exception):
    """Base application error."""
    def __init__(self, message: str, code: str):
        self.message = message
        self.code = code
        super().__init__(message)

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str):
        super().__init__(
            message=f"{resource} with id {id} not found",
            code="NOT_FOUND"
        )

class ValidationError(AppError):
    def __init__(self, details: list[str]):
        self.details = details
        super().__init__(
            message="Validation failed",
            code="VALIDATION_ERROR"
        )
```

### Result Pattern

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E", bound=Exception)

@dataclass
class Success(Generic[T]):
    data: T
    success: bool = True

@dataclass
class Failure(Generic[E]):
    error: E
    success: bool = False

Result = Success[T] | Failure[E]

async def get_user(user_id: str) -> Result[User, NotFoundError]:
    user = await db.users.find_one({"id": user_id})
    if user is None:
        return Failure(NotFoundError("User", user_id))
    return Success(User(**user))
```

## Testing

### pytest Example

```python
import pytest
from unittest.mock import AsyncMock, patch

class TestUserService:
    @pytest.fixture
    def mock_repo(self):
        return AsyncMock()

    @pytest.fixture
    def service(self, mock_repo):
        return UserService(mock_repo)

    async def test_get_user_returns_user_when_found(
        self, service, mock_repo
    ):
        # Arrange
        user = User(id="1", name="John")
        mock_repo.find_by_id.return_value = user

        # Act
        result = await service.get_user("1")

        # Assert
        assert result.success is True
        assert result.data == user

    async def test_get_user_returns_error_when_not_found(
        self, service, mock_repo
    ):
        # Arrange
        mock_repo.find_by_id.return_value = None

        # Act
        result = await service.get_user("999")

        # Assert
        assert result.success is False
        assert isinstance(result.error, NotFoundError)
```

## Common Commands

```bash
# Linting
ruff check .
ruff check --fix .

# Formatting
ruff format .
black .

# Type checking
mypy .

# Testing
pytest
pytest -v
pytest --cov=app
pytest -x  # Stop on first failure

# Dependencies
pip install -r requirements.txt
pip freeze > requirements.txt
pip-audit  # Security audit
```

## Framework-Specific Patterns

For framework-specific guidance, see:
- [FastAPI patterns](FASTAPI.md)
- [Django patterns](DJANGO.md)

## Rules

- ALWAYS use type hints
- ALWAYS use Pydantic for data validation
- NEVER use mutable default arguments
- ALWAYS handle exceptions explicitly
- NEVER use bare except
- ALWAYS use context managers for resources
- NEVER hardcode secrets
- ALWAYS use virtual environments
