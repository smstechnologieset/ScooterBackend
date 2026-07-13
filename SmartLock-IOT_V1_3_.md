# DONGGUAN SHENGUOKE ELECTRONIC DIGITAL TECHNOLOGY CO., LTD

**Yiwei Guard Public Bicycle**
**IOT**

R&D Department
2023/6/5

---

# Yiweiwei Public Bicycle Intelligent Lock Protocol Rev1.3

*Dongguan Shenguoke Electronic Digital Technology Co., Ltd*

## Document History

### Revision record

| version | date | author | Change description |
|---|---|---|---|
| 1.0 | 2020-05-08 | 林良 | Initial version |
| 1.1 | 2021-07-10 | 林良 | Add multiple authentication options |
| 1.2 | 2022-03-18 | 林良 | Add operation and maintenance unlock command (lock storage or transportation) |
| 1.3 | 2023-06-5 | 林良 | Modify the lock return information |

---

## 1 Basic functions of smart lock

## 2 Intelligent lock recognition information

This identification information is actually a lock number, which should be included in both Bluetooth broadcast names and 4G-LTE uplink packets.

The broadcast mode of Bluetooth is "GK: xxxxxxxxxxVVV", where GK: remains unchanged; Among them, "xxxxxxxxxxx" 12 digits represent the lock number, and VVV represents the battery voltage of this lock.

In the 4G-LTE upload information package, it should be included in the ID at the beginning of the package, as detailed in the protocol format instructions.

## 3 Protocol Format

### 1. 4G-LTE and Platform

The communication between the two is in packet format, with the content in character form and separated by a "#" symbol. The format is as follows:

`ID # MAC # Sequential Number # Length # Content$`

1. ID: For example, G168， Length 4, fixed and unchanged, used to distinguish hardware models with different functions
2. MAC: 00000000000, length 12, digital characters, which is a 12 bit lock number.
3. Sequential Number: 0000~ffff, length 4, hexadecimal, terminal adds 1 every time it sends;
4. Length: 0000~ffff, length 4, refers to the length of the content section, starting from # and excluding #, hexadecimal;
5. Content: The actual content shall prevail. The agreement ends with the symbol $and is terminated. The overall form of the content adopts: 'Keywords: parameters, parameters, etc.'; Keywords: parameters, parameters, etc. The content can be multiple parallel fields separated by semicolons, with field keywords starting and colons leading to parameters. Multiple corresponding parameters are also allowed, and parameters are separated by commas.
6. End character $, length includes this character.

### 2. Bluetooth and mobile app

The communication between the two is in the format of data packets. If the phone sends a super Bluetooth connection and the lock is not unlocked after more than 10 seconds of connection time, the connection will be automatically disconnected. After the lock is successfully unlocked, the Bluetooth connection will be maintained until the APP actively disconnects or the lock is successfully reported and disconnected.

Bluetooth should not send more than 20 bytes at a time. Note that when sending more than 20 bytes, the instruction should be divided into blocks

Service UUID:0x6E400000B5A3F393E0A9E50E24DCCA9E

Feature: 0002 APP writes data

Feature: 0003 is data sent via Bluetooth notification

**Packet Format**

| Starting segment | Information body length segment | Information function segment | Information Segment | Verification section |
|---|---|---|---|---|
| 2 bytes (0x7B,0x5B) | 1 byte | 1 byte | N bytes (maximum length 255) | 1 byte |

1. Information body length segment: refers to the byte length occupied by the information body segment;
2. Information function segment: refers to the functions to be implemented, such as unlocking and locking;
3. Information segment: refers to the information attached to this function;
4. Verification section: The bytes of the information function section and the information body section are different or different.

## 4 Function Description

### 4.1 Positioning package*

Compatible with public self-propelled platforms：

1. A) Upstream: `G168 # 0000000000 # Sequential Number # Length # LOCA: L;CELL: Base station information; GDATA: GPS information; ALERT: Alarm information; STATUS: Status information$`
   B) Upstream: `G168 # 0000000000 # Sequential Number # Length # GDATA: GPS information; ALERT: Alarm information; STATUS: Status information$`
2. A) Downward: `G168 # 0000000000 # Sequential Number # Length # ACK ^ LOCA$`
   B) Downward: `G168 # 0000000000 # Sequential Number # Length # ACK ^ GDATA$`

Note: Upstream refers to GSM uploading data packets to the server, while downstream refers to the server sending data to the end.

**Example：**

```
#LOCA:G;CELL:1,460,2,2795,1435,64;GDATA:A,12,160412154800,22.564025,113.242329,5.5,152,900;ALERT:00;STATUS:410,500,22,1$
#GDATA:A,12,160412154800,22.564025,113.242329,5.5,152,900;STATUS:410,500,22,1$
```

**Description of each field：**

1. LOCA indicates that this is a positioning packet type, L=base station positioning, G=GPS positioning, W=WiFi positioning;
2. CELL field information (not available after version 1.8)
3. GDATA field information (nB: non fixed length)

| Positioning effectiveness | Number of satellites (nB) | GPS Time | latitude | longitude | speed（nB） | direction（nB） | altitude（nB） |
|---|---|---|---|---|---|---|---|

For example: GDATA:A,12, 160412154800,22.564025, 113.242329, 5.5,152,900;

a) Validity: A represents the validity of latitude and longitude, V represents the invalidity of latitude and longitude. If this positioning packet is L, it indicates the positioning of the base station, and the validity is "A". At this time, only the latitude and longitude values are valid, and other data in this packet is invalid

b) The number of satellites refers to the number of valid satellites found by the lock end. Generally, positioning requires more than 4 satellites, and this is invalid when the base station positioning packet is sent.

c) GPS time: in the format of year, month, day, hour, minute, and second. The year is two characters, and this is invalid when the base station positioning packet is used.

d) Latitude: accurate to 6 decimal places, with a negative sign at the beginning indicating the southern hemisphere;

e) Longitude: Accurate to 6 decimal places, with a negative sign at the beginning indicating the Western Hemisphere;

Represented in the example: Effective, 12 stars, April 12, 2016 at 15:48:00; The latitude is 22.564025, longitude is 113.242329, speed is 5.5 kilometers per hour, direction is 152 degrees, and altitude is 900 meters.

4. ALERT field ALERT: 00 indicates normal, and the following parameters can refer to the error code in the appendix.
5. Status fields such as Status: 410,500, 22,1; Indicates battery level of 4.10V, solar voltage of 5.00V, communication signal strength of 22, current locked state. If 00, it indicates the current unlocked state; 01 represents the current locked state, 03 represents the unknown locked state; FF indicates that there is no communication with the surge lock, and the current status of 09 is abnormal. It is neither locked nor unlocked.

A brand new platform, in order to save traffic, has removed base station positioning:

Upstream: `G168 # 0000000000 # Sequential Number # Length # GDATA: GPS information; ALERT: Alarm information; STATUS: Status information$`

Downward: `G168 # 0000000000 # Sequential Number # Length # ACK ^ GDATA$`

Note: Upstream refers to 4G-LTE uploading data packets to the server, while downstream refers to the server sending data to the end。

**Example：**

```
#GDATA:A,12,160412154800,22.564025,113.242329,5.5,152,900;ALERT:00;STATUS:410,500,22,1$
```

### 4.2 Heartbeat packet (4G-LTE only for long connections)

1. Upstream: `G168 # 0000000000 # Sequential Number # Length # SYNC: number; STATUS: Status information$`
2. Downward: `G168 # 0000000000 # Sequential Number # Length # ACK ^ SYNC: UNIX Timestamp$`

**Description of each field：**

1. SYNC field, heartbeat increment from 000 to fff;
2. UNIX timestamp: 1493436690, represented by 10 cross characters, used for synchronizing system time.

**Example：**

```
Upstream:G168#EE6E8C646034#0000#001B#SYNC:000;STATUS:388,085,22,1,0$
Downward:G168#EE6E8C646034#0000#0014#ACK^SYNC:1501892203$
```

### 4.3 Search for or inquire about vehicles (4G-LTE section only for long connections)

This function is used to check the condition of the car and understand its condition before unlocking to see if there are

1. Downward: `G168 # 0000000000 # Sequential Number # Length # APPLY: Parameters$`
2. Upstream: `G168 # 0000000000 # Sequential Number # Length # ACK ^ APPLY: Lock Status, Lock Type, Hardware Version, Software Version$`

**Example：**

```
below；G168#EE6E8C646034#000D#0009#APPLY:00$
Upper；G168#EE6E8C646034#000D#0015#ACK^APPLY:00,02,11,52$
```

**Description of each field：**

1. When the APPLY field parameter is 00, only the lock status is known; 01 Understand the lock condition and trigger the horn to sound; 02 Understand the lock condition and trigger the upload of the positioning package, 03 Report the CCID Sequential Number of the SIM card。
2. Lock status (whether car rental is allowed), only here if 0x00 indicates the current lock status (allowing car rental); 0x01 represents the current unlocked state; 03 indicates unknown status; 0xFF indicates no communication with the surge lock; 0x09 The current state is abnormal, neither locked nor unlocked.

In the Bluetooth section, a random code is obtained for unlocking and encrypting

1. APP sending：0x7B5B0161 00 61 或 0x7B5B0161 01 60

The 00 in the content section indicates only checking the condition of the car, while the 01 indicates checking the condition of the car while the car horn is sounding.

2. Bluetooth response：

| Data header 0x7B0x5B | Information body length | informative function 0x91 | Lock status 1B | Hardware version 1B | Software version 1B | Can I rent it 1B | RAND random number 4B | battery voltage 2 bytes (Hexadecimal system） | Verification section |
|---|---|---|---|---|---|---|---|---|---|

Among them, the RAD random number 4B is an integer data (big end representation), which the APP needs to convert into 8B lowercase character representation for unlocking encryption. The random number read is an integer, such as 0x1f3e332a, which needs to be converted into a string "1f3e332a", case sensitive, using lowercase characters, and saved for the next Bluetooth unlock step.

### 4.4 Unlock (4G-LTE section only for long connections)

The server downloads unlock data and waits for the lock to return

1. below:；`G168 # 0000000000 # Sequential Number # Length # OPEN:00, Phone Number, Timestamp$`
2. Upper；`G168 # 0000000000 # Sequential Number # Length # ACK ^ OPEN: Error Code$`
3. example：

```
Below；G168#EE6E8C646034#000D#001F#OPEN:00,013645678902,1506864202$
Upper；G168#EE6E8C646034#000D#000C#ACK^OPEN:00$
```

Attention: Before sending the unlock command on 4G-LTE, you can request to rent a car first. If there is a timely return, the network is relatively good. After the 4G-LTE unlock command is issued, due to the instability of the 4G-LTE network, if it returns success or failure within 25 seconds, it will enter the corresponding processing. If there is no return after the timeout, it can be charged and handled by the user. After the network stabilizes, the lock will upload lock status information. After the unlocking command is issued, the lock status of the heartbeat packet or empty record packet cannot be used to identify the success or failure of the current lock unlocking within 25 seconds. It is necessary to prevent misjudgment if the lock just goes up the heartbeat packet when the unlocking command is issued.

**Sending via Bluetooth app**

| Data header 0x7B-0x5B | Information body length | informative function 0x62 | secret key index | Phone number: 6B (half section representation) | time stamp 4B (Big End) | AES (8B Character Type Random) Machine number+8 '0s' added) 16B | Verification section |
|---|---|---|---|---|---|---|---|

Note: Before unlocking via Bluetooth, it is necessary to search for the car and obtain a random code

**Bluetooth response**

| Data header0x7B-0x5B | Information body length | informative function0x92 | Error code 1B | Verification section |
|---|---|---|---|---|

Explanation: The phone number generally refers to the user's mobile phone number, which can also be the user's registered ID number.

Encryption instructions: When locks are produced and shipped, there will be a table where each lock's lock number corresponds to an 80 character password table

| MAC | 密码表 |
|---|---|
| C0671322CFC1 | 6ep6jqYgsYDWS3QSEBhJPhrMKDzK1Z1EGlv5nr4nymp1Tp8CsvqsIVQyWQ9tP8BP2UzIMzXxG9ZGb042 |

This needs to be linked to the car number for storage. After scanning the QR code of the car number and accessing the server, the user will receive this MAC, which is the lock number, and obtain these 80 characters. The key index is randomly generated by the APP or server, with a value range of 0-64. When the index is 0, the 16 character key obtained in the above figure is: KEY="6ep6jqYgsYDWS3QS", Fill the random number string obtained during the previous car search with 8 '0s', i.e. RAND="1f3e332a00000000" Then AES (KEY, RAND) ECB obtains 0xA189A97C55CDCDD95F979D248FF00931 hexadecimal plus data.

The obtained unlocking data 0x7B5B 1B 62 00 013645678902 59D0EC4A A189A97C55CDCDD95F979D248FF00931 is divided into 94 blocks (each block does not exceed 20 bytes) and sent to the Bluetooth lock. When there is no response within the 10 second timeout, the record can be read to confirm whether the unlocking was successful or failed.

Note: In version 1.2, an operation and maintenance unlock command has been added to this unlock command. The Bluetooth operation and maintenance unlock command replaces 0x62 in the unlock command with 0x6b, and the lock returns 0x9b; The remote operation and maintenance unlock command is changed from OPEN to STOR, and ACK ^ STOR is returned

Error codes can be found in the appendix。

### 4.5 close and lock

The server downloads unlock data and waits for the lock to return

below: `G168 # 0000000000 # Sequential Number # Length # LOCK:00$`

upper： `G168 # 0000000000 # Sequential Number # Length # ACK ^ LOCK: Error Code, Lock Status, Parking Status, Hall Status$`

Locked state: 0 unlocked state; 1. Locked state; The other three are unknown;

Parking status: 0 parked, 1 in motion;

Hall state: 0 normal, other abnormalities;.

**example：**

```
Below；G168#EE6E8C646034#000D#0008#LOCK:00$
Upper；G168#EE6E8C646034#000D#000C#ACK^LOCK:00,1,0,0$
```

Attention: Before sending the lock command from 4G-LTE, you can first search for the vehicle and trigger the positioning. You need to wait for 15 seconds to 1 minute before uploading the positioning package.

The error code can be found in the appendix.

**Sending via Bluetooth app**

| Data header 0x7B-0x5B | Information body length | informative function 0x66 | Parameter 1B | Key Index | AES (8B Character Type Random) Machine number+8 '0s' added) 16B | Verification section |
|---|---|---|---|---|---|---|

The normal locking parameters are usually 0x00. When it is necessary to add a locking situation, the parameters, key index, and AES should be changed in the same way as the unlocking method.

**Bluetooth response**

| Data header 0x7B-0x5B | Information body length | informative function 0x96 | Error code 1B | Verification section |
|---|---|---|---|---|

### 4.6 transaction record

Transaction record: It is to ensure that the server can reliably receive data packets initiated by the IOT end when the lock status changes, and of course, the platform can also actively request them. After unlocking, a record of unlocking will be generated, which includes identification (user ID and unlocking timestamp), status, and unlocking time. After closing the lock, a record of the lock will also be generated, including the identification (user ID and unlock timestamp), status, and lock closing time. This record is saved using a first in, first out caching method.

After unlocking, in addition to responding to commands, the lock will report unlocking records through 4G-LTE. When closing the lock, if Bluetooth and the phone are connected, a lock prompt will be sent to the phone via Bluetooth first (see 4.8 Automatic Return), allowing the phone to extract transaction records. After the lock is turned off, if the Bluetooth connection to the phone fails to read the record or the Bluetooth is disconnected, the transaction record will be reported to the server through 4G-LTE. If the 4G-LTE remains abnormal, it will be saved continuously. Before the next Bluetooth unlock, the record can be read and reported to the server to correct the billing of the previous user, which has reference value.

It is necessary to continuously read transaction records through response until 0 records are read

1. Up: `# 000000 # Sequential Number # Length # RECORD: Current Lock Status 1B, Transaction Information$`
2. Below: `G168 # 0000000000 # Sequential Number # Length # ACK ^ RECORD: Transaction Information$`

**Example：**

```
Up:G168#EE6E8C646034#000D#0056#RECORD:0,1504562378,013686000902,0, 1504562378,5A00109547177DD45C8A358D45D5EDA8,00,388$
Below：G168#EE6E8C646034#000D#0025# ACK^RECORD:1504562378,013686000902,0$
```

UP1) RECORD in the previous example: Current lock status (if 00 represents the current unlocked state; 01 represents the current locked state; FF represents no communication with the circuit breaker lock; 09 represents abnormal current status, neither locked nor unlocked); The red text represents transaction information: unlock timestamp, user ID, status of this record (0 indicates unlock record and 1 indicates lock record), time of this record, AES verification code (compatible, this content does not need to be processed), key index, and finally battery voltage.

2) The downstream transaction information only takes the unlock timestamp, phone number, and status of the received upstream transaction information. That is to say RECORD: unlock timestamp, phone number, this record status $()

3) If a record without transaction information is received, such as RECORD: 1 $, it means that the lock has no record available and should not be logged again xx, Otherwise, the lock will repeatedly store empty records, and this cycle will increase the power consumption of the lock.

If the server wants to read records, it can download `G168 # EE6E8C646034 # 000D # 0008 # RECORD: $`, which means the server actively requests to read transaction records

**Bluetooth protocol**

1. Smart lock sending: 0x7b-0x5b-0x00-0x99-0x99 indicates the lock, please request the APP to read the transaction record.
2. APP actively reads and sends: 0x7b-0x5b-0x00-0x68-0x68 (can be sent at any time)
3. Bluetooth response:

| Data header 0x7B-0x5B | Information body length | Information function 0x98 | Current lock status 1B | Transaction information (see table below for details) | Verification section |
|---|---|---|---|---|---|

The current locked state, if 0x00, indicates the current unlocked state; 0x01 represents the current locked state; 0xFF indicates no communication with the surge lock, 0x09 is currently in an abnormal state and is neither locked nor unlocked.

4. After reading the transaction information, the APP responds (will extract the next record):

| Data header 0x7B-0x5B | Information body length | Information function 0x98 | Received transaction information Lock number - timestamp of unlocking - phone number - lock status | Verification section |
|---|---|---|---|---|

Note: Do not return to the current locked state

**Specific implementation of transaction information；**

1；The transaction information column includes the following information

| Lock number 12B (4G-LTE not required) | When unlocking time stamp 4B (Big End) | Car renter's phone number Number 6B | Transaction lock status Unlock is 0 Lock to 1 1B | Transaction timestamp 4B (big end) | AES (lock number+timestamp when unlocked) ^ lock status 16B | secret key index 1B | battery voltage 2B (small end) |
|---|---|---|---|---|---|---|---|

1. 4G-LTE notation：

```
1493436574,13688899900, 0 14934366900, (32B characters represent 16B-AES data), 01420
```

example：

```
G168#E895B187706D#0000#0055#RECORD:0,1495782582,013600000068,0,066825164,4D8E177BF40E2A4177E066CBEABEC745,02,409$
G168#E895B187706D#0000#0055#RECORD:0,1495782582,013600000068,0,066825164,409$(Remove AES data and key index after version 1.8）
```

2. Bluetooth notation: 890123456712- (timestamp replaced with 4-byte HEX) -0x13688899900 (half byte represents one bit, which is represented by 6 bytes) -0- (timestamp replaced with 4-byte HEX) - encrypted data 16B-index -0X1A4 (the "-" should be removed here for illustration only)

3. If there is no transaction information, everything is empty

### 4.7 Heartbeat packet upload interval setting

This function is used to set the heartbeat packet upload interval for continuous device online. As the interval varies in different regions, it is recommended to increase the interval as much as possible to ensure low power consumption while also ensuring terminal online. The value range is 050-999 seconds, measured in seconds.

1. Below: `G168 # 0000000000 # Sequential Number # Length # INTERSYNC: Parameters$`
2. Up: `G168 # 0000000000 # Sequential Number # Length # ACK ^ INTERSYNC: Parameters$`

**example：**

```
Below；G168#EE6E8C646034#000D#000E#INTERSYNC:240$
Upper；G168#EE6E8C646034#000D#0012#ACK^INTERSYNC:240$
```

### 4.8 Lock positioning package upload interval setting

This function is used to set the device interval to enable GPS positioning. Due to the high power consumption of enabling GPS positioning, it is necessary to carefully set the upload interval in minutes, with a value range of 0060-1000 minutes。

1. Below: `G168 # 0000000000 # Sequential Number # Length # INTERARMLOC: Parameters$`
2. upper: `G168 # 0000000000 # Sequential Number # Length # ACK ^ INTERARMLOC: Parameter$`

**example：**

```
Below:G168#EE6E8C646034#000E#0011#INTERARMLOC:1000$
upper:G168#EE6E8C646034#000E#0015#ACK^INTERARMLOC:1000$
```

### 4.9 Cycling positioning package upload interval setting

This function is used to set the GPS positioning upload interval of the device in cycling mode. Due to the high power consumption of enabling GPS positioning, it is necessary to carefully set the upload interval in seconds, with a value range of 015-999 seconds. 000 indicates off.

1. Below: `G168 # 0000000000 # Sequential Number # Length # SETRIDELOC: Parameter$`
2. upper: `G168 # 0000000000 # Sequential Number # Length # ACK ^ SETRIDELOC: Parameter$`

**example：**

```
Below;G168#EE6E8C646034#000E#000E#SETRIDELOC:600$
Upper;G168#EE6E8C646034#000E#0013#ACK^SETRIDELOC:600$
```

### 4.10 Remote firmware update protocol

By searching for the car to obtain the software version number, when remote updates are needed, update protocols are issued remotely every once in a while. After the update is complete, the software version number is obtained. If it matches the current latest version number, no updates will be issued.

**Remote disconnection controller electrical protocol format:**

1. Below;`G168 # 0000000000 # Sequential Number # Length # UPDATE:00$`
2. Upper;`G168 # 0000000000 # Sequential Number # Length # ACK ^ UPDATE:00$`

**example：**

```
Below;G168#EE6E8C646034#000E#000A#UPDATE:00$
Upper;G168#EE6E8C646034#000D#0014#ACK^UPDATE:00$
```

If it returns with a value of 00, it indicates that the terminal has started the upgrade process, while others indicate that the terminal is busy and unable to process. Please request again after a period of time.

### 4.11 Report the CCID Sequential Number of the SIM card

1. When the lock exits factory mode or is powered on, it will automatically report the CCID number
2. Server downstream request `G168 # EE6E8C646034 # 000D # 0009 # APPLY: 03 $`, parameter 03 will trigger CCID reporting。

Below:`G168 # 0000000000 # Sequential Number # Length # CCID:<20 digit Sequential Number>$`

Upper;`G168 # 0000000000 # Sequential Number # Length # ACK ^ CCID:<20 bit Sequential Number>$`

**example：**

```
Below:G168#F546F81E0F26#0002#001A#CCID:898607B0011700926067$
Upper;G168#F546F81E0F26#0002#001E#ACK^CCID: 898607B0011700926067$
```

### 4.12 Proactively report version number

Every time the network is locked, this packet will be sent first for reporting.

Upper;`G168 # 0000000000 # Sequential Number # Length # Register: Hardware Version Number, Software Version Number$`

Below:`G168 # 0000000000 # Sequential Number # Length # ACK ^ Register: pubbike$`

**example：**

```
Upper;G168#F546F81E0F26#0002#001A#REGISTER:66,80$
Below:G168#F546F81E0F26#0002#001E#ACK^REGISTER:pubbike$
```

**Certification 2：**

For example, the 80 character key of D1EE83D9C5DC

`VWNzIwWQ8KDNQSjc78SxJmdjxZoTXJZG2p1oGlr6e2lLatwrLCuBNaCqfP8uqsyhjfsY30JyYUH5o3UM`

Every time the network is connected, this packet will be sent first for reporting。

Upper;`G168 # 0000000000 # Sequential Number # Length # Register: The first 6 digits of the key, hardware version number, software version number$`

Below:`G168 # 0000000000 # Sequential Number # Length # ACK ^ Register: 7-12 bits of the key$`

**example：**

```
Upper;G168#D1EE83D9C5DC#0002#001A#REGISTER:VWNzIw,66,80$
Below:G168#D1EE83D9C5DC#0002#001E#ACK^REGISTER:WQ8KDN$
```

**Certification 3：**

For example, the 80 character key of D1EE83D9C5DC

`VWNzIwWQ8KDNQSjc78SxJmdjxZoTXJZG2p1oGlr6e2lLatwrLCuBNaCqfP8uqsyhjfsY30JyYUH5o3UM`

Every time the network is connected, the following packets will be reported first。

Upper:`G168 # 0000000000 # Sequential Number # Length # AuthOR:00$`

Below:`G168 # 0000000000 # Sequential Number # Length # ACK ^ AuthOR: Key Lower Label$`

Key label: randomly ranging from 0-68, cannot be greater than 68,

Upper;`G168 # 0000000000 # Sequential Number # Length # Register: Key label 0-6 digits, hardware version number, software version number, reconnection code$`

Below:`G168 # 0000000000 # Sequential Number # Length # ACK ^ Register: 7-12 bits of the label under the key$`

**example：**

```
Upper;G168#D1EE83D9C5DC#0002#001A#AUTHOR:00$
Below:G168#D1EE83D9C5DC#0002#001E#ACK^AUTHOR:5$
Upper;G168#D1EE83D9C5DC#0002#001A#REGISTER:wWQ8KD,66,80,1$
Below:G168#D1EE83D9C5DC#0002#001E#ACK^REGISTER:NQSjc7$
```

### 4.13 Modify the unlock and lock voice commands

For locks with TTS voice function, if you want to modify the voice broadcast content for unlocking and closing the lock, please modify according to this protocol

Below;`G168 # 0000000000 # Sequential Number # Length # VOICE: Number, "Voice Content"$`

Upper;`G168 # 0000000000 # Sequential Number # Length # ACK ^ VOICE: Number$`

Number: 01 indicates unlocking voice content, 02 indicates closing voice content. If the up middle number returns an FF value, it indicates that the format is incorrect.

Voice content: GBK characters are required and cannot exceed 22 Chinese characters.

**example：**

```
Below;G168#F546F81E0F26#0002#001A#VOICE:01,"你好，欢迎使用共享单车"$
Upper;G168#F546F81E0F26#0002#000D#ACK^VOICE:01$
```

### 4.14 Bluetooth Connection Authentication

After unlocking the APP, it will default that the current Bluetooth connection is authenticated. If the connection is disconnected for some reason during cycling, the APP should restart the connection and send an authentication command. Otherwise, after 10 seconds, the IOT terminal will automatically disconnect the unauthenticated connection and will not receive a lock command.

The encryption process is the same as unlocking, first obtaining the dynamic code and then encrypting it;

**Sending via Bluetooth app**

| Data header 0x7B-0x5B | Information body length | Information function 0x67 | secret key index | AES (8B Character Type Random) Machine number+8 '0s' added) 16B | Verification section |
|---|---|---|---|---|---|

**蓝牙回应**

| Data header 0x7B-0x5B | Information body length | Information function 0x97 | Error code 1B | Verification section |
|---|---|---|---|---|

### 4.15 Lock body upgrade and version number (temporarily omitted)

## 5 Attach error code：

00: Successful
FF: unknown error
FE: Low Battery
FD: Inspection section error or encryption error
FC: Transaction record overflow
FA: Switching lock failed, did not leave the lock position or close the lock position, indicating motor failure;
F9: Indicates that the time for receiving the unlock command has exceeded the time limit；
F6: Unlocking failed, mechanical malfunction occurred before reaching the unlocking position
F5: Locking failed, mechanical failure did not reach the locking position；
F3: Unable to communicate with the lock body;
F2: Do not lock the bike while riding；
F0: Hall fault, if it is determined that the user is not riding, please attach the FF parameter when closing the lock and forcibly close it (only supported if necessary)。
