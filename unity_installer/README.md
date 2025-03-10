# 🚀 Unity Hub & Editor Deployment with Jamf

## 📌 Overview
This repository provides an automated solution for deploying **Unity Hub** and the **latest Unity Editor** on macOS machines using **Jamf Pro**. The script handles:

✅ **Silent installation** of Unity Hub & Unity Editor (latest version)
✅ **Automated keychain credential setup** for Unity Hub login
✅ **Jamf Pro integration** with a **Configuration Profile** to suppress keychain prompts
✅ **Logging & fail-safe mechanisms** to ensure reliability across multiple deployments

## 📂 Repository Contents
- `install_unity_hub_serialize.sh` → Main installation & setup script
- `config_profile.mobileconfig` → Jamf **PPPC Configuration Profile** (needed for Keychain access)
- `README.md` → You're reading this! 📖

## 🔧 Prerequisites
### **1️⃣ Jamf Pro Configuration**
- Deploy the **PPPC Configuration Profile** (`config_profile.mobileconfig`) in Jamf.
- Ensure it grants **Keychain access** to `com.unity3d.unityhub`.
- Verify that Jamf policies allow script execution.

### **2️⃣ Mac Admin Setup**
- Ensure a **local admin account** (`name is whatever`) exists on target machines.
- For companies that are more durable and do not have an admin account or roate that password, this may not work. But, create a fork.
- The script assumes Unity credentials belong to `what ever email you used to sign up with`.

## 🛠️ Installation Steps
### **Step 1: Upload the Configuration Profile**
1. Go to **Jamf Pro** → **Configuration Profiles**.
2. Upload `config_profile.mobileconfig`.
3. Scope it to the target machines.

### **Step 2: Deploy the Script in Jamf**
1. In **Jamf Pro**, go to **Policies**.
2. Create a new policy:
   - **Trigger**: Recurring Check-in or Enrollment Complete.
   - **Execution Frequency**: Once per computer.
   - **Scripts**: Add `install_unity_hub_serialize.sh`.
3. Scope it to the target devices.
4. Deploy the policy.

### **Step 3: Verify Deployment**
- Check logs in **Jamf Pro** (`Policy Logs` section).
- Run manually for debugging:  
  ```bash
  sudo sh install_unity_hub_serialize.sh
  ```
- Validate Keychain entry:  
  ```bash
  security find-generic-password -s "com.unity3d.unityhub" -a "whatever email you used in Unity"
  ```

## 🛠️ Troubleshooting
| Issue | Possible Cause | Fix |
|--------|--------------|------|
| Unity Hub prompts for login | Keychain entry missing | Run `security find-generic-password` check |
| Unity Editor not installing | Incorrect download URL | Verify Unity Editor URL logic in script |
| Script fails in Jamf | PPPC profile not applied | Ensure `config_profile.mobileconfig` is deployed |

## 🚀 Future Improvements
- Implement **offline package caching** to reduce network dependency.
- Add **multi-user support** for seamless installations on shared devices.
- Enhance **error handling & recovery mechanisms** for failed deployments.
- Fix Config profile to handle passing the credentials to everyones keychain. Needs work in the script to dynamically do that. 

## 📢 Contributing
If you have improvements, submit a PR or open an issue!

## 📢 NEW FIXES 
3/10/2025 Due to time and testing, I cannot get the serializing to happen w/o user. I updated the script to:
✅ Downloads and installs the latest Unity Hub
✅ Uses Unity Hub to install Unity Editor 6+ (latest)
✅ Ensures robust logging at every step
✅ No login required—just downloads and installs Unity
✅ Fails safely, retries downloads if needed, and ensures everything is installed correctly
Download & Install the Latest Unity Hub 
✅ (Already working in the script)
Use Unity Hub CLI to Download Unity 6+ Automatically

# 🛠️ Command:
/Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --headless install --version latest
---
⚡ **Author:** Joe (Hawk) Mancuso   
📅 **Last Updated:** March 6, 2025  
🐧 **Tested On:** macOS Ventura 13.x & Jamf Pro 11.x

