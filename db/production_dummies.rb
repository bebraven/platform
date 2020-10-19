# This file will create dummy data for the application, if not already present.
# This SHOULD be used in production, but not in Highlander.
# See https://app.asana.com/0/1174274412967132/1197893935338145/f
# Add any dummy objects here that you need to use as a fallback in Booster/Prod.

# Add a dummy course.
# Note: Do NOT change this name! It is used to select the course.
Course.find_or_create_by!(name: 'Production Dummy')
