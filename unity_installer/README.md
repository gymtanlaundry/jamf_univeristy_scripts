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
- Ensure a **local admin account** (`Macadmin`) exists on target machines.
- The script assumes Unity credentials belong to `software@quinnipiac.edu`.

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
  security find-generic-password -s "com.unity3d.unityhub" -a "software@quinnipiac.edu"
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

## 📢 Contributing
If you have improvements, submit a PR or open an issue!

---
⚡ **Author:** Your Name  
📅 **Last Updated:** March 6, 2025  
🐧 **Tested On:** macOS Ventura 13.x & Jamf Pro

