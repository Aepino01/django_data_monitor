#!/bin/sh
set -e

echo "==> Migrating database"
python manage.py migrate --noinput

echo "==> Collecting static files"
python manage.py collectstatic --noinput --clear

echo "==> Creating superuser if not exists"
python - <<'PY'
import os, django
django.setup()
from django.contrib.auth import get_user_model

User = get_user_model()
u = os.environ.get("DJANGO_SUPERUSER_USERNAME")
e = os.environ.get("DJANGO_SUPERUSER_EMAIL")
p = os.environ.get("DJANGO_SUPERUSER_PASSWORD")

if u and e and p:
    if not User.objects.filter(username=u).exists():
        User.objects.create_superuser(username=u, email=e, password=p)
        print(f"Superuser {u} created")
    else:
        print(f"Superuser {u} already exists")
else:
    print("Superuser vars missing, skipping")
PY

echo "==> Starting Gunicorn"
exec gunicorn backend_analytics_server.wsgi:application --bind 0.0.0.0:8000

