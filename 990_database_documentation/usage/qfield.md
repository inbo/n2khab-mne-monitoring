---
aliases:
  - software/qfield
  - qfield
tags: 
  - gis
  - mobile
  - app
---

- <https://qfield.org>
- Project files are regularly updated and distributed via google drive.
- Prior to project updates, photos should be exported by users: on some devices, old photos were not recovered.

## Automatic Login
QField has the option to store database login credentials in an `xml` file on your mobile device.
A `qgis_auth_generic.xml` file can be found on our shared drive. It contains the following short xml code:
```xml
<!DOCTYPE qgis_authentication>
<qgis_authentication>
  <configurations>
    <AuthMethodConfig method="Basic" name="me@mnmdb" id="mnmuser" version="2" uri="">
      <Config password="my_password" realm="" username="my_username"/>
    </AuthMethodConfig>
  </configurations>
</qgis_authentication>
```
This `xml` must be modified with a text editor to contain your credentials (`username` and `password`). As `id`, it is good to keep `mnmuser`.

> [!warning] sensitive information
> These credentials are sensitive information and should not be shared with others.

Then, move the `xml` to the following path on the mobile device:
```
<phone>/Android/data/ch.opengis.qfield/files/QField/auth/
```
(This can be done via usb debugging, or by navigating your phone in the Windows file explorer.)

If everything was done correctly, the app should now automatically log in to our postgres database.


## Photo Export
- select your project
- in the project menu (icon with three bars on the top left), select *project settings* (folder icon with gears)
- in the menu of the DCIM folder (three vertical dots on the right)
- send compressed folder to... e.g. Drive
- store the `zip` file on our shared drive under "photos"