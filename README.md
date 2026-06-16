# deploy_agent_abenigne
Building a project factory as a deploy agent.
As required this script utomates the creation of the Student Attendance Tracker project by building the
folder structure, writing the source files, letting the user update attendance
thresholds, and checking that a user's environment is ready to run the app.
# To run this script, you should first write these commands in the terminal:
chmod +x setup_project.sh
./setup_project.sh
# You will be prompted for:
A project name suffix (please write any word that you want)
Whether to update the attendance thresholds (yes/no)
If yes, you will input new warning and failure values.
# The directory structure was created identically as required
# To run the attendance app, use:
cd attendance_tracker_{name}
python3 attendance_checker.py
# How to Trigger the Archive Feature
   # Press Ctrl+C at any point while the script is running.
   # The script catches the interrupt (SIGINT) and automatically:
Bundles everything created so far into attendance_tracker_{name}_archive.tar.gz
Deletes the incomplete attendance_tracker_{name}/ folder
This keeps your workspace clean even if setup is cancelled midway.

# Health Check
Before finishing, the script verifies:
if python3 is installed, using python3 --version
All four required files exist in the correct locations
#If anything is missing, a clear warning is printed.
