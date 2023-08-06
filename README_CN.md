# Outline-Keycloak-Installer
- Outline Wiki 一键安装脚本，使用 Keycloak 作为前置登录组件，以支持多用户管理，可多用户同时在线编辑。
- 请使用不少于 4G RAM 的宿主机安装，否则可能经常崩溃，建议用大于等于 2C8G 的宿主机安装。

# 使用方法

## 安装

- clone / 直接下载本仓库，复制 user-config.json.template，并重命名为 user-config.json
- 支持的配置内容(请不要直接复制下面的注释，JSON 不支持带注释):

```
{
    # 安装类型，目前只有全新安装 "new".
    "installType": "new",

    # SSO 管理员用户名，同时也是 Outline 管理员用户名。
    "adminUsername": "bi0x",

    # SSO 管理员密码，请不要使用太简单的密码！
    "adminPassword": "bi0xi0bi0xi0b",

    # SSO 访问地址，Outline 配置需要使用。
    "ssoURL": "http://example.bi0x.com:6001/",

    # SSO 登录按钮展示的信息。
    "ssoName": "Keycloak SSO",

    # SSO 容器对外 HTTP 端口。
    "ssoHttpPort": "6001",

    # SSO 容器对外 HTTPs 端口。
    "ssoHttpsPort": "6002",

    # 数据库访问用 IP / 也可以填域名。
    "sqlIP": "example.bi0x.com",

    # 数据库容器对外端口。
    "sqlPort": "6432",

    # MinIO 存储访问地址。
    "minioBucketURL": "http://example.bi0x.com:9000/",

    # MinIO 存储端口。
    "minioBucketPort": "9000",

    # MinIO Web 管理界面端口。
    "minioAdminPort": "9001",

    # Outline 容器对外端口。
    "outlinePort": "6003",

    # Outline 访问地址。
    "outlineBaseUrl": "http://example.bi0x.com:6003/"
}
```
- 确认配置无误后 `bash install_outline.sh`，等待执行完成。
- 访问 Outline 地址，使用设置的账户密码即可登录。
- **安装成功后请不要删除本项目，相关运行数据存储在项目文件夹中 `./outline-data` 下，删除将导致数据丢失 / 运行异常。**

## 多用户配置

- 访问 SSO 地址，使用上述设置的账户密码登录。
- 点击左侧 Manage 上方的下拉列表，切换至 `outline_realm_xxxx` 域。
- 切换到左侧 Users，点击 Add User，
- 配置 `Required user actions` 加上 `Update Password` 和 `Update Profile`,
- 设置 Username，Email，First name, Last name 后 Create.
    - 如果要求了用户 `Update Profile`，可以不配置邮箱和姓名，用户初次登陆的时候会被要求填写邮箱信息。
    - 如果没有要求用户更新信息，一定要配置邮箱和姓名，Outline 需要用户邮箱信息才能正常登录，不配置邮箱将导致登陆失败。
- 这时用户已创建，会自动跳转到用户详情页，需要添加密码才能登陆，
- 在用户详情页中切换到 `Credentials` 下，点击 Set password 设置密码，勾上 Temporary 的话，用户初次登录会被要求修改密码。
- 配置完密码后，用户即可登录。

## 安装失败的处理方法

- 删除掉项目目录下 outline-data 文件夹 `sudo rm -rf ./outline-data`
- 删除掉和本次安装相关的容器，使用 `docker ps -a | grep outline-data` 可以看到信息。
- 之后可排查相关问题，重新配置，运行安装脚本。
