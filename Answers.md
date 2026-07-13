Hello,
To avoid another back-and-forth, please answer the following questions for the exact smart lock hardware and firmware version that will be shipped to us. We are preparing the production backend and need to configure the server correctly before we give you the final permanent IP address and TCP port.
Please reply in English if possible, and please keep all sample packets exactly as the firmware sends/receives them, including case, punctuation, leading zeros, #, :, ;, ,, and $.
1.Confirm the exact lock hardware and firmware
1.Please confirm that the documents we received apply to the exact lock hardware and firmware that will be installed in our scooters.(Yes 需要确认)
2.Please confirm the exact hardware model ID (for example G168) and whether it is the same for all units.(It is the same for all units.)
3.Please confirm whether all scooters in our batch use the same protocol revision and authentication mode.(All use the same)
2.Network connection details
1.Does the lock connect to the server using raw TCP only?(Yes ,using raw TCP)
2.Does the lock support IPv4 only, or IPv4 and DNS hostname?(Support IPV4 and hostname)
3.Does the lock support TLS/SSL, or only plain TCP?(Only Tcp)
4.Should we provide you with only a public IPv4 and TCP port, or can we provide a domain name instead?(Domain or ip)
5.Does one lock keep one long TCP connection open continuously?（Yes,one lock keep one long  TCP connection）
6.What is the expected reconnect behavior if the server closes the socket or the mobile network drops?(When the lock is disconnected, it will actively reconnect to the server. The reconnection interval starts at 10 seconds and gradually increases to 30 minutes. If the connection keeps failing, the lock will retry the connection every 30 minutes.)
3.Packet format
1.Please confirm the exact 4G packet format:(Yes,confirmed)
ID#MAC#SEQ#LENGTH#CONTENT$
2.Please confirm whether there are any spaces in real packets, or whether spaces are only used in the document for readability.(no spaces in real packets)
3.Is the packet content always ASCII, except for commands like VOICE that may use GBK?(Yes always ASCII except GBK)
4.Are keywords case-sensitive? For example, should we treat REGISTER, Register, AUTHOR, and AuthOR as the same or different?(Yes,keywords are case-sensitive)
5.Please confirm whether the MAC/lock number is always 12 characters and whether it may contain hexadecimal letters A-F (examples in the document do).(Yes,It always 12 characters(ASCII range:0-1,A-F))
4.LENGTH field
1.Please confirm exactly how LENGTH is calculated.
G168#EE6E8C646034#0000#0014#ACK^SYNC:1501892203$ 
“ACK^SYNC:1501892203$” 20 bytes(characters) ,so length is 0x0014
2.Does LENGTH include the final $ byte or not?(Yes include)
3.Is LENGTH the byte length or the character length?(byte length)
4.For commands containing non-ASCII content such as VOICE, is LENGTH calculated on encoded bytes (for example GBK bytes) or characters?(GBK is two bytes)
5.Please give 3 real packet examples from actual firmware where the correct LENGTH can be verified clearly.()
G168#EE6E8C646034#0000#0014#ACK^SYNC:1501892203$  (0x0014,total 20bytes)

5.Sequence number rules
1.Please confirm whether SEQ is always 4 hexadecimal characters.(4 hex characters.)
2.When the server replies to an upstream packet, must the server reuse the same SEQ value?(same SEQ value)
3.When the server sends a downlink command such as OPEN or LOCK, does the terminal reply using the same SEQ?(Yes, same SEQ value)
4.If packets are retried, should the same SEQ be reused or should a new one be generated?(A new one be generated)
6.Registration and authentication mode
Please confirm exactly which mode our locks use at network connection time:
(Authentication is mainly designed from the server-side perspective. Currently, Mode 1 is universally adopted, primarily for uploading the version number)
Mode 1
REGISTER:hw,sw
server replies ACK^REGISTER:pubbike
Up:G168#F546F81E0F26#0002#001A#REGISTER:66,80,e$
Down:G168#F546F81E0F26#0002#001E#ACK^REGISTER:pubbike$


Mode 2
REGISTER:first6key,hw,sw
server replies ACK^REGISTER:next6key
Mode 3
AUTHOR:00
server replies ACK^AUTHOR:index
lock sends REGISTER:keySegment,hw,sw,reconnectCode
server replies ACK^REGISTER:nextKeySegment
For the mode you use, please provide:
one real REGISTER sample from the lock
the exact required server response
whether authentication is mandatory before any other command is accepted
whether the 80-character key table must be stored on our backend
whether you will provide the full key table for every lock before launch
1.Real sample packets from actual firmware
Please send real packet samples copied from actual lock logs for the following:
oREGISTER
oAUTHOR (if used)
oSYNC
oGDATA or LOCA
oAPPLY response
oOPEN success response
oOPEN failure response
oLOCK success response
oLOCK failure response
oRECORD upload
oRECORD empty/no-record case
oCCID report
(Examples shall be provided in the protocol document. Meanwhile, since the lock initiates the connection actively, you can install a simulated server software on your PC, and then configure the lock to point to the temporary server IP to analyze the actual data packets.）
Please include both the terminal packet and the exact server reply expected for each one.
1.OPEN command
oPlease confirm the exact OPEN command format.
oIn OPEN:00,PhoneNumber,Timestamp, must the second field always be the user’s 12-digit phone number, or can it be another 12-digit user ID?(can other user ID,however, the format and digit count of numbers or letters must be identical.)
oIf it is not a phone number, what exact format should we send?(This depends on whether the server side uses it. The lock only records the value and does not care about its actual content.)
oIs the timestamp always a 10-digit Unix timestamp in UTC?(Yes,Unit is second)
oPlease confirm the timeout rule: the document says to wait up to 25 seconds for unlock result. Is 25 seconds the official value we should use in production?(Yes,After send Open-Command, wait for 25 sec)
oIf no ACK^OPEN arrives within timeout, what is the recommended backend behavior?(In addition to the response of the result, the confirmation can also be done through the uploaded transaction records.If there is no response and no transaction record, you can prompt the user to confirm whether the lock is opened. If the user taps "Not Opened", the system will close the order and replace the vehicle.)
2.LOCK command
oPlease confirm the exact LOCK command format.
oPlease confirm the meaning of the returned fields in:
ACK^LOCK:ErrorCode,LockStatus,ParkingStatus,HallStatus
oPlease confirm whether the server may send LOCK:FF for force lock when hall fault F0 occurs, and under what conditions this is safe.
(Specific examples can be referred to in the documentation or understood via the prototype. If there is an unsafe Hall fault, it is recommended to submit the faulty vehicle to the operation and maintenance team for handling. The O&M staff can forcefully close the order without re-locking the lock.)
3.RECORD command and billing reliability
oPlease confirm the exact meaning of every field in RECORD.
oPlease confirm whether the server must acknowledge every non-empty RECORD packet with:
ACK^RECORD:unlockTimestamp,userId,recordStatus (Yes ,must acknowledge.
(Since the status packet is actively reported repeatedly to ensure the server keeps track of the lock's execution status, it differs from the scenario where only a single response is sent upon receiving an unlock/lock command — the response packet might get lost due to network issues.)
oIf the lock sends an empty/no-record packet such as RECORD:1$, should the server send any ACK or should it ignore it?
(Never send a response. Otherwise, the lock will mistakenly identify it as the server querying its status and record status, and keep uploading empty record packets. The actively uploaded empty record packets are triggered when the lock encounters network anomalies or loses the original order information, in which case it only reports its current status.)
oPlease confirm whether records should continue to be read until the lock reports no more records.(Yes,should continue) 
oPlease confirm whether RECORD after version 1.8 may omit AES data and key index, as shown in the document.(It is unnecessary to pay attention to the AES information unless it is required, as this information is only requested by a small number of users.)
4.STATUS field
oPlease confirm the exact meaning and order of all STATUS parameters.
oSome examples appear to contain 4 parameters and others 5 parameters. Please provide the exact field definition used by our firmware.(Only the first 4 parameters are used. If there is a 5th parameter, it will be ignored, which is mainly for compatibility with some users' protocols.)
oPlease confirm the values for locked, unlocked, unknown, no communication, and abnormal state.( locked:01, unlocked:00, unknown:03, no communication:FF, and abnormal state:09.) 
o
5.GPS / LOCA / GDATA
oPlease confirm whether our locks will send both LOCA and GDATA, or only GDATA.
oPlease confirm whether CELL is still used on our firmware.
oPlease confirm whether the server must always reply ACK^LOCA or ACK^GDATA depending on the packet received.
oPlease provide one real positioning packet from our actual firmware.
{The general version uses  LOCA.)
G168#F0EABAE375F0#5EA6#007C#LOCA:G;CELL:1,0,0,0000,0000,0;GDATA:A,14,260518152619,24.994177,102.651884,1.16,06.22,1861.6;ALERT:00;STATUS:376,441,25,1,0$
ACK^LOCA
6.CCID and version reporting
oPlease confirm whether the lock will always report CCID automatically at boot/network connect.
oPlease confirm whether the server must reply ACK^CCID:<same value>.(Yes)
oPlease confirm whether every network connection begins with a REGISTER/version report.
(It can be obtained through “APPLY:03 “ command. Or first open commad)
7.Optional commands
Please confirm whether the following commands are supported on our locks and whether we should implement them now:
oSTOR operation and maintenance unlock
oUPDATE (must implement)
oVOICE
oINTERSYNC
oINTERARMLOC
oSETRIDELOC
oserver-initiated RECORD: read request  (must implement)
8.Bluetooth-related confirmation for future app support
Even though our current focus is the 4G backend, please also confirm:
othe exact BLE service UUID
0x6E400000B5A3F393E0A9E50E24DCCA9E
othe exact write characteristic UUID
0x6E400020B5A3F393E0A9E50E24DCCA9E
othe exact notify characteristic UUID
0x6E400030B5A3F393E0A9E50E24DCCA9E
owhether the unlock/authentication AES process in the BLE section is correct as written
owhether the app should ever receive the full 80-character key from the backend, or whether you recommend server-side encryption instead
(These 80 characters will be submitted to the platform through a form during the factory production process)
9.Error codes
oPlease confirm the full final list of error codes for our firmware.
oPlease confirm whether the appendix values are final and complete.
oPlease confirm especially the meaning of: FD, FA, F9, F6, F5, F3, F2, F0.
(For now, these are all the fault codes, and more will be added according to the specific situation.)
10.Final deployment requirement
Before we give you the permanent production server address, please confirm:
oexactly what IP/port format you need from us
owhether one permanent public IPv4 and one TCP port is enough for all scooters
owhether you recommend we first test one lock on a staging port before binding the final production port into all hardware
(Such as: iot.baidu.com:6009 or  47.113.212.223:6009, Yes,when debug,you can use the test domain or ip,when production during, use the production domain .