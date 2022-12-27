# Amber Enphase Zero Export Switcher Tool (Zest)

Zest is a small background program to automatically prevent your battery-less [Enphase]https://enphase.com/ solar system from exporting energy to the grid while your [Amber Electric](https://www.amber.com.au/) solar feed-in tariff is negative. This avoids the disappointment of being charged money due to your solar system exporting energy to the grid at a bad time!

## How it works

Enphase devices are configured with a 'Grid Profile', which encompasses a whole lot of power parameters - including a limit of how much power you are permitted to export to the grid. As an example, I have an 8.2kW solar system, but in my area, the power distribution company (responsible for the power poles and wires), Jemena, impose a 5kW export limit. What this means is that even if there is enough sunshine to generate the full 8.2kW, if the power consumption of my home is not high enough, the system limits its generation capacity so that it never exports more than 5kW to the grid. It is this capability that can be utilised, to set the grid export limit to 0.

With such an amount of energy 'going to waste', I could be better off to buy a battery to store it in and use later. Also, the 'self-consumption' mode - which I think is the battery equivalent of what I'm trying to achieve - is better supported with a battery. But for financial reasons, it's not on my agenda to buy a battery. I do plan to instead eventually buy an EV and smart charger which can serve as a home battery; but that is quite some time away. So this program will be rather handy in the meantime.

The Envoy has a web server accessible on LAN, by pointing a web browser at its IP address. The homepage is not password-protected, but other pages are. Some require the homeowner credentials, and some are intended for use by the system installer. On one of the installer pages, there is a select box where you can choose the grid profile to use. Originally, I only had one grid profile available - the 5kW export limit one - but thankfully, I was able to easily get Enphase to add a 0kW export limit one. Now it is just a matter of changing the selected profile. And that can be done programmatically by this program.

The program polls the Amber API for your feed-in price, and when it crosses the $0 threshold, the appropriate grid profile is applied.

## Setup

### System requirements

This may work with different Enphase systems, but here's what I have:

- Gateway
    + Enphase Envoy-S-Metered-EU
        * SKU: ENV-S-WM-230
        * **Software version: D5.0.55 (4f2662)**
- Microinverters
    + Enphase IQ7A
        * SKU: IQ7A-72-2-INT
- A computer to run this on, which can remain:
    + Connected to the local network
    + Running during daylight hours at least

### Dependencies

- [Install Ruby 3](https://www.ruby-lang.org/en/downloads/)
- Download the contents of this repository
- Install the gems using Bundler:
    + Open a terminal within the program's folder and run `bundle`

### Configuration

Create a file called `.env` containing the following:

```
ZEST_LOG_LEVEL=debug

ZEST_AMBER_TOKEN=[your token from Amber]
ZEST_AMBER_SITE_ID=[your site ID from Amber]

ZEST_ENPHASE_ENVOY_INSTALLER_USERNAME=installer
ZEST_ENPHASE_ENVOY_INSTALLER_PASSWORD=[your installer password]
ZEST_ENPHASE_ENVOY_GRID_PROFILE_NAME_NORMAL_EXPORT="[your normal grid profile name]"
ZEST_ENPHASE_ENVOY_GRID_PROFILE_NAME_ZERO_EXPORT="[your zero-export grid profile name]"
```

#### Amber token

You can generate an Amber token on the 'For Developers' page: https://app.amber.com.au/developers. Enable 'Developer Mode' in the 'Settings' page to gain access to this. When asked for a name for the token, you can enter something like 'Amber Enphase Zero Export Switcher Tool'.

#### Amber site ID

To find your Amber site ID:

- Go to Amber's 'For Developers' page
- Click the 'Authorize' button at top-right
- Paste your token in the box and click 'Authorize' then 'Close'
- Expand the `GET /sites` section
- Click 'Try it out'
- Click 'Execute'
- Under the 'Server Response' heading, you should now see a response body containing an ID field. Note that this is distinct from the example response body just below

#### Envoy installer password

The default installer password can be algorithmically generated from the Envoy's serial number. I am very grateful for the prior work done by others to figure this out. To generate it, there are a few options:

- [An Android app by thecomputerperson](https://thecomputerperson.wordpress.com/2016/08/28/reverse-engineering-the-enphase-installer-toolkit/)
- [A Python script by Markus Fritze](https://github.com/sarnau/EnphaseEnergy)
- [A webpage by Tristan Mott](https://blahnana.com/passwordcalc.html) (easiest)

[Apparently, firmware version 7 replaces this method of authentication](https://support.enphase.com/s/question/0D53m00006ySLuRCAW/unimpressed-with-loss-of-local-api-connectivity-to-envoys?t=1672164431932) with a [token that has to be refreshed through a UI](https://enphase.com/download/iq-gateway-access-using-token-tech-brief) every six months. I haven't read much of the thread, but it sounds like you also lose access to realtime telemetry by upgrading, so I'll be trying to avoid that.

### Grid profile names

You can find these at: `http://your-envoy-ip/installer/setup/home#microinverters/status/profile`. Note that if you go to that URL directly, you'll be redirected to another page; just enter the URL again and it will then take you to the right one:

![](doc/images/envoy-grid-profile-setting-page.png)

The dropdown shows what profiles you have available, e.g.:

![](doc/images/envoy-grid-profile-setting-page-dropdown.png)

Note that it seems grid profiles have a real name and a display name. In my case, they are practically identical, but for an additional space in the 5kW one's real name. As an example, the real names of my grid profiles are:

- `AS/NZS 4777.2: 2020 Australia A Region  5 kW Export Limit:1.2.2`
- `AS/NZS 4777.2: 2020 Australia A Region 0 kW Export Limit:1.2.2`

You need the real name of each. This can be found with the inspector in Chrome: Right-click on one of the items in the dropdown -> Inspect.

Some HTML code will appear, with one line highlighted, e.g.:

![](doc/images/envoy-grid-profile-setting-page-dropdown-item-inspected.png)

Double-click on the profile name that's next to `id=` and copy it, e.g. `select2-profile_select-result-t33g-AS/NZS 4777.2: 2020 Australia A Region  5 kW Export Limit:1.2.2`. Trim `select2-profile_select-result-t33g-` or similar from the start, and you now have your real profile name, e.g. `AS/NZS 4777.2: 2020 Australia A Region  5 kW Export Limit:1.2.2`.

If you don't have a zero export grid profile selectable, contact Enphase or maybe your installer to request that they add one for you. I sent Enphase a message, and impressively, they'd added a copy of my grid profile with zero export within an hour.

## Run the program

To start the program, open a terminal in the program's folder and run:

```
ruby zest.rb
```
