# Binary Protocol

## Raw Frame

### No Encryption, No Seq
`0xAA 0x00 0x05 0xFF 0x00 0x00 0x00 0x00`

    byte   magic  - 0xAA   (1 byte)
    short  size   - 0x0005 (2 bytes)
    byte   opcode - 0xFF   (1 byte)
    byte[] data   - ...    (size - 1 byte)

### Static Encryption, Seq
`0xAA 0x00 0x05 0xFF 0x01 0x00 0x00 0x00`

    byte   magic       - 0xAA   (1 byte)
    short  size        - 0x0005 (2 bytes)
    byte   opcode      - 0xFF   (1 byte)
    byte   seq         - 0x01   (1 byte)
    byte[] encrypted   - ...    (size - 1 byte)


### Stream Encryption, Seq
`0xAA 0x00 0x08 0xFF 0x01 0x00 0x00 0x00 0xFF 0xFF 0xFF`

    byte   magic       - 0xAA     (1 byte)
    short  size        - 0x0008   (2 bytes)
    byte   opcode      - 0xFF     (1 byte)
    byte   seq         - 0x01     (1 byte)
    byte[] encrypted   - ...      (size - 4 byte)
    byte[] trailer     - 0xFFFFFF (3 bytes)

## Decrypted Data Frame

### Ingress (From Client to Server)

#### 0x00 - Client Version

#### 0x02 - Check Name/Password Valid for Create

#### 0x03 - Auth Client

#### 0x04 - Create Character

#### 0x05 - Request Map Data

#### 0x06 - Move Player Entity, Request Map Data

#### 0x07 - Player Pickup

#### 0x08 - Player Drop Item

#### 0x09 - Player Look

#### 0x0A - ? Maybe ("Player Look At" in Mithia)

#### 0x0B - End Session

#### 0x0C - Request Missing Object

#### 0x0D - Ignore Player

#### 0x0E - Player Say

#### 0x0F - Player Cast Spell

#### 0x10 - Resume Session

#### 0x11 - Change Player Entity Direction

#### 0x12 - Player Wield

#### 0x13 - Player Swing

#### 0x17 - Player Throw

#### 0x18 - View Userlist

#### 0x19 - Player Whisper

#### 0x1A - Player Eat

#### 0x1B - Change Status (Mount, Turn on/off settings)

Turn off Whisper/Group/Shout/Advice/Magic/Weather/Realm Center/Exchange/Fast Move/Clan Chat/Sound/View Helm/Necklace

#### 0x1C - Player Use Item

#### 0x1D - Player Emotion

#### 0x1E - Player Equip Item

#### 0x1F - Player Unequip Item

#### 0x20 - Player Open Door

#### 0x23 - ? Maybe (PaperPopupWriteSave)

#### 0x24 - Player Drop Gold

#### 0x26 - Change Player Password

#### 0x27 - Request Quest

#### 0x29 - Player Give Item

#### 0x2A - Player Give Gold

#### 0x2D - Request Player Status + Request Group Status

#### 0x2E - Add Member to Group

#### 0x30 - Rearrange Spells or Rearrange Inventory

#### 0x32 - Move Player Entity

#### 0x34 - Player Post Item

#### 0x38 - Client Resync

#### 0x39 - Menu Input Response

#### 0x3A - Menu Wizard Response

#### 0x3B - Request Boards

#### 0x3F - ? Maybe ("Map Change")

#### 0x41 - Click Parcel

#### 0x42 - ? Maybe ("Client Crash Debug)

#### 0x43 - Client Click Entity

#### 0x4A - Client Exchange

#### 0x4C - Client Powerboards

#### 0x4F - Player Profile Save

#### 0x57 - Unknown ("Multi Server?")

#### 0x60 - Ping

#### 0x62 - Unknown ("Baram")

#### 0x66 - Client Request Towns

#### 0x69 - ? Maybe ("Ubstruction")

#### 0x6B - Creation System

#### 0x71 - Keepalive

#### 0x73 - Web Board

#### 0x75 - ? Maybe ("Walk Pong")

#### 0x77 - Friends

#### 0x7B - Request Meta List + Request Meta File

#### 0x7C - Request Minimap

#### 0x7D - Request Ranking

#### 0x82 - Client Camera Change

#### 0x83 - ? Maybe ("Screenshots")

#### 0x84 - Hunter List

#### 0x85 - Click Hunter

    0x00 - Request Meta File
    0x01 - Request Meta List

### Egress (From Server to Client)

#### 0x00 - ? Set Encryption Key and Patch Client

**Notes** 

In Mithia code is set after receiving the Client Version. Nothing bad seems to happen if not sent.

#### 0x02 -  Login Screen Message + Auth Client

**Notes**

Used to popup a message for login failure, character creation. If no message, the client transitions from the login window the game mode window.

#### 0x03 - Transfer to Server

#### 0x04 - Player Coordinates

#### 0x05 - Player Entity ID

#### 0x06 - Map Data

#### 0x07 - Map Floor Object

#### 0x08 - Player Stats

#### 0x09 - Show Board Questionnaire

#### 0x10 - Remove Inventory Item

#### 0x0A - Message

    0x00 - whisper
    0x03 - status
    0x04 - system
    0x08 - popup
    0x11 - group
    0x12 - clan

#### 0x0B - Move Player (Slow)

#### 0x0C - Move Entity

#### 0x0D - Chat

    0x00 - Say
    0x01 - Yell

#### 0x0E - Destroy Entity

Mithia sends this one for Mob type 1, PC, PC, npctype 1, bl->type == BL_MOB

#### 0x0F - Add Inventory Item

#### 0x11 - Entity Direction

#### 0x12 - Send Guide

#### 0x13 - Send Entity Health

#### 0x15 - Load Map

#### 0x16 - Send Item Thrown

#### 0x17 - Send Spellbook

#### 0x18 - Remove from Spellbook

#### 0x19 - Send Background Music + Send Sound

#### 0X1A - Send Action

#### 0x1B - Writable Paper Popup

#### 0x1D - Update Entity

#### 0x1E - Accept Server Transfer

#### 0x1F - Send Weather

#### 0x20 - Send Time

#### 0x22 - Send Refresh Finished

#### 0x23 - Send Options

#### 0x26 - Move Player (Edge)

#### 0x29 - Send Animation

#### 0x2E - Map Select

This is related to the map selector when you move between towns

#### 0x2F - Send Menu (Input)

#### 0x30 - Send Menu (Wizard)

#### 0x31 - Send Boards

#### 0x33 - Create Entity

#### 0x34 - Send Entity Status

#### 0x35 - Paper Popup

#### 0x36 - Send User List

#### 0x37 - Player Equipt

#### 0x38 - Player Unequipt

#### 0x39 - Send My Status

#### 0x3A - Send Duration

#### 0x3B - Unused (Heartbeat)

#### 0x3D - Unused (Clan Bank)

#### 0x3F - Send Player Status (Aethers, Etc)

#### 0x42 - Exchange

#### 0x46 - Send Powerboard

#### 0x4E - Send Player Confirm Throw

#### 0x49 - ? Unsure Retrieve Profile

#### 0x51 - Block Movement

#### 0x58 - Send Screen Message

Can also destroy?

#### 0x59 - Send Towns

#### 0x5A - ? Unkown (Screensaver)

#### 0x5F - Destroy Entity

Unsure when this one is used vs 0x0E

#### 0x62 - Send Profile / Send Web Board

#### 0x63 - Send Group Status

#### 0x66 - Send URL?

#### 0x67 - Send Timer

#### 0x68 - Pong

#### 0x6F - Meta File Data + Meta List Data

#### 0x70 - Send Mini Map

#### 0x7D - Ranking

#### 0x83 - Send Hunter Toggle

#### 0x84 - Send Hunter Note
