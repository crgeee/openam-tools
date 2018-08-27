# Description

This tool will automatically configure OpenAM's server settings and is designed to run within an automated build. However, it also supports running standalone. See steps below.

It uses two tools provided by OpenAM: SSOAdminTools-13.0.0 and SSOConfiguratorTools-13.0.0 which can be obtained from ForgeRock.

# Initial steps

## pass
pass is a hashed password file used to set the admin passwords in config.properties. The the current salt is set to "password1234!" inside the execute.sh script. Change this password and generate this file for automated builds. You can also ignore this file if you pass the argument -p to set your admin passwords.

Use the following line to generate a new hashed pass file:
```
test
```

## config.properties
Set the domains related to your OpenAM configuration. You can use this sample configuration as a guide. It is currently configurd to use LDAP as your datastore. This configuration may also be generated using the SSOADM tool or by referencing the admin section of an existing installation of OpenAM.

## execute.sh
Set the paths for your openam-13 installation.

# How to run standalone

1. Unzip openam-tools.zip or clone to /openam-13/openam-tools.
2. Ensure /openam-13/openam-tools folder contains the SSOConfiguratorTools-13.0.0.zip and SSOAdminTools-13.0.0.zip. If not, please download from alice.grid or ForgeRock and drop into opemam-tools directory.
3. Remove /openam-13/config folder if it exists. The script will recreate this folder with correct user and permissions.
4. <b>Optional</b>: If you removed the /openam-13/config folder in previous step, reboot machine to restart openam. Allow the server a few minutes to restart.
5. <b>Optional</b>: if you don't want to use the default configuration settings, adjust config.properties. Keep admin passwords blank.
6. <b>Optional</b>: if you don't want to use the default admin password, use -p "<adminPassword>".
7. Execute "./execute.sh" as root. A backup of config.properties will be made.
8. <b>Optional</b>: Remove /openam-13/openam-tools directory when you are finished.

# Arguments

-p
Use -p <password> flag to use a custom password


# SSOADM Commands Reference
```
get-attr-defs


Get the default attribute values in a schema.

Syntax
ssoadm get-attr-defs options [--global-options]

Options
--servicename, -s
The name of the service.

--schematype, -t
The type of schema.

--adminid, -u
The administrator ID running the command.

--password-file, -f
The filename that contains the password of the administrator.

[--subschemaname, -c]
The name of the sub schema.

[--attributenames, -a]
The names of the attribute.
```

```
set-attr-defs


Set the default attribute values in a schema.

Syntax
ssoadm set-attr-defs options [--global-options]

Options
--servicename, -s
The name of the service.

--schematype, -t
The type of schema. Tells ssoadm the section of the service definition the attribute resides; from the console we have global, organization (means realm) and dynamic.

--adminid, -u
The administrator ID running the command.

--password-file, -f
The filename that contains the password of the administrator.

[--subschemaname, -c]
The name of the sub schema.

[--attributevalues, -a]
The attribute values. For example, homeaddress=here.

[--datafile, -D]
Name of file that contains attributes and corresponding values as in attribute-name=attribute-value. Enter one attribute and value per line.
```

# How to debug configurator install

Look at /openam-13/config/install.log


# Useful Links


- OpenAM 13 Tools Installation Guide:
  - https://backstage.forgerock.com/docs/openam/13/install-guide/#chap-install-tools

- ssoadmin commands:
  - https://wikis.forgerock.org/confluence/display/openam/OpenAM+ssoadm+command
  - https://backstage.forgerock.com/docs/openam/13/reference/#ssoadm-1
  - https://wikis.forgerock.org/confluence/display/openam/Attributes+and+the+ssoadm+command
