# Outline-Keycloak-Installer
> 中文，请看 README_CN.md
- Outline Wiki install script. Using [Keycloak](https://github.com/keycloak/keycloak) as Single SignOn for multi users management.
- Need at least 4G RAM for installation, otherwise it will crash frequently.
    - It is recommended to use no less than 2 cores and 8G RAM for installation.

# Usage

## Installation

- clone this repository. Copy `user-config.json.template` and rename it with `user-config.json`
- Config details: (Please do not directly copy all example below, because JSON does not support comments):

```
{
    # Installation type, Only support "new" installation now.
    "installType": "new",

    # SSO admin username, also as Outline admin username.
    "adminUsername": "bi0x",

    # SSO admin password. Please use a strong password.
    "adminPassword": "bi0xi0bi0xi0b",

    # SSO access URL.
    "ssoURL": "http://example.bi0x.com:6001/",

    # SSO login button text.
    "ssoName": "Keycloak SSO",

    # SSO external HTTP port.
    "ssoHttpPort": "6001",

    # SSO external HTTPs port.
    "ssoHttpsPort": "6002",

    # Database access IP / domain.
    "sqlIP": "example.bi0x.com",

    # Database external port.
    "sqlPort": "6432",

    # MinIO bucket access URL.
    "minioBucketURL": "http://192.168.50.17:9000/",

    # MinIO bucket external port.
    "minioBucketPort": "9000",

    # MinIO web management port.
    "minioAdminPort": "9001",

    # Outline external port.
    "outlinePort": "6003",

    # Outline access URL.
    "outlineBaseUrl": "http://192.168.50.17:6003/"
}
```
- Please make sure user-config.json is correct. Then use `bash install_outline.sh` to start installation.
- After installation, you can access Outline URL and login.
    - If Outline cannot be accesseed, wait a few secounds.
- **Please do not delete this project after installation. The Outline data is stored in `./outline-data` in the project folder. Deleting it will result in data loss and abnormal operation.**

## Multi user management

- Access the SSO address, login with admin account.
- Click the drop-down list above `Manage` tab on the left, and switch to the `outline_realm_xxxx` domain.
- Switch to `Users` tab on the left, click `Add User`.
- Set `Required user actions` with `Update Password` and `Update Profile`,
- Set `Username`, `Email`, `First name`, `Last name` then `Create`.
    - If the user is required to `Update Profile`, it is not necessary to configure the email and name. The user will be force to fill in the email and name info when first time login.
    - If the user is not required to `Update Profile`, the email and name must be configured. Outline needs the user name and email information to login normally. If the email address is not configured, the login will fail.
- After user been created, it will automatically redirect to the user details page. You need to add a password to log in.
- On the user details page, switch to `Credentials` tab, click `Set password` to set a password, and if `Temporary` is checked, the user will be required to change the password when first time login.
- After configuring the password, the user can login successfully.

## Handling installation falure

- Delete the `outline-data` folder in the project directory with `sudo rm -rf ./outline-data`
- Delete the container related to installation, you can use `docker ps -a | grep outline-data` to see the related containers.
- After that, you can reconfigure settings and try re-run the installation script.
