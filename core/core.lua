local Biddikus, C, L, _ = unpack(select(2, ...))

Biddikus = LibStub("AceAddon-3.0"):NewAddon("Biddikus", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local screenWidth			= floor(GetScreenWidth())
local screenHeight			= floor(GetScreenHeight())

local _G		= _G
local select	= _G.select
local unpack	= _G.unpack
local type		= _G.type
local floor		= _G.math.floor
local min		= _G.math.min
local strbyte	= _G.string.byte
local format	= _G.string.format
local strlen	= _G.string.len
local strsub	= _G.string.sub
local strmatch	= _G.string.match

local pairs		= _G.pairs
local tinsert	= _G.table.insert
local sort		= _G.table.sort
local wipe		= _G.table.wipe

local GetTime				= _G.GetTime
local GetNumGroupMembers	= _G.GetNumGroupMembers
local GetNumSubgroupMembers	= _G.GetNumSubgroupMembers
local GetInstanceInfo		= _G.GetInstanceInfo
local IsInRaid				= _G.IsInRaid
local UnitAffectingCombat	= _G.UnitAffectingCombat
local UnitClass				= _G.UnitClass
local UnitExists			= _G.UnitExists
local UnitIsFriend			= _G.UnitIsFriend
local UnitCanAssist			= _G.UnitCanAssist
local UnitIsPlayer			= _G.UnitIsPlayer
local UnitName				= _G.UnitName
local UnitReaction			= _G.UnitReaction
local UnitIsUnit 			= _G.UnitIsUnit
local FindAuraByName		= AuraUtil.FindAuraByName

local FACTION_BAR_COLORS	= _G.FACTION_BAR_COLORS
local RAID_CLASS_COLORS		= (_G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS)

-- Variables
Biddikus.prefix = "Biddikus"
Biddikus.userAgent = "Biddikus-0.0.1"
Biddikus.message_welcome = "Type /biddikus for options."

Biddikus.version = GetAddOnMetadata("Biddikus", "Version")
Biddikus.addonName = "Biddikus"

Biddikus.inRaid = false
Biddikus.playerName = nil
Biddikus.masterLooterName = nil

Biddikus.bid = {
    item = nil,
    minimum = nil,
    state = nil,
    timer = nil,
    timerCount = nil,
    timerMax = nil,
    currentBid = nil,
    currentPlayer = nil,
    currentClass = nil,
}
Biddikus.item = nil

Biddikus.options = {
	name = "Biddikus",
	handler = Biddikus,
	type = "group",
	args = {
        general = {
            order = 1,
			type = "group",
            name = "General",
            args = {
                enable = {
                    order = 1, 
                    type = "toggle",
                    name = "Enable Biddkus",
                    desc = "Enables Biddikus bidding management",
                    get = function(info) 
                        Biddikus:UpdateFrame()
                        return(Biddikus.db.profile.enable) 
                    end,
                    set = function(info, key) Biddikus.db.profile.enable=key end
                },
                increment = {
                    order = 2, 
                    type = "range",
                    min = 0.1,
                    max = 100,
                    step = 0.1,
                    name = "Automatic Bid Increment",
                    desc = "Auto increment your next bid by this amount",
                    get = function(info) return(Biddikus.db.profile.bidIncrement) end,
                    set = function(info, key) Biddikus.db.profile.bidIncrement=key end
                },
                nickname = {
                    order = 3,
                    type = "input",
                    name = "Nickname",
                    desc = "Set a custom nickname to replace your character name during bids",
                    get = function(info) return(Biddikus.db.profile.nickname) end,
                    set = function(info, key)
                        if key == '' then
                            key = nil
                        end
                        Biddikus.db.profile.nickname=key end
                },
                flash = {
                    order = 5,
                    type = "toggle",
                    name = "Enable Screen Flash",
                    desc = "Enable bid timeout screen flash",
                    get = function(info) return(Biddikus.db.profile.flash) end,
                    set = function(info, key) Biddikus.db.profile.flash=key end
                },
                raidWarningStart = {
                    order = 6, 
                    type = "toggle",
                    name = "Enable Bid Start Warning",
                    desc = "Warns you about bid start with a raid warning message",
                    get = function(info) 
                        Biddikus:UpdateFrame()
                        return(Biddikus.db.profile.raidWarningStart) 
                    end,
                    set = function(info, key) Biddikus.db.profile.raidWarningStart=key end
                },
                raidWarningEnd = {
                    order = 7, 
                    type = "toggle",
                    name = "Enable Bid End Warnings",
                    desc = "Warns you about bids timing out",
                    get = function(info) 
                        Biddikus:UpdateFrame()
                        return(Biddikus.db.profile.raidWarningEnd) 
                    end,
                    set = function(info, key) Biddikus.db.profile.raidWarningEnd=key end
                },
                autohide = {
                    order = 8, 
                    type = "toggle",
                    name = "Auto Hide",
                    desc = "Hides Biddikus when not bidding",
                    get = function(info) 
                        Biddikus:UpdateFrame()
                        return(Biddikus.db.profile.autohide) 
                    end,
                    set = function(info, key) Biddikus.db.profile.autohide=key end
                },

            }
        },
        appearance = {
			order = 2,
			type = "group",
			name = "Appearance",
			get = function(info)
				return C[info[2]][info[3]]
			end,
			set = function(info, value)
				C[info[2]][info[3]] = value
				Biddikus:UpdateFrame()
			end,
			args = {
				frame = {
					order = 1,
					name = "Frame",
					type = "group",
					inline = true,
					args = {
						locked = {
							order = 1,
							name = "Locked",
							type = "toggle",
						},
						strata = {
							order = 2,
							name = "Strata",
							type = "select",
							values = {
								["1-BACKGROUND"] = "BACKGROUND",
								["2-LOW"] = "LOW",
								["3-MEDIUM"] = "MEDIUM",
								["4-HIGH"] = "HIGH",
								["5-DIALOG"] = "DIALOG",
								["6-FULLSCREEN"] = "FULLSCREEN",
								["7-FULLSCREEN_DIALOG"] = "FULLSCREEN_DIALOG",
								["8-TOOLTIP"] = "TOOLTIP",
							},
							style = "dropdown",
						},
						headerShow = {
							order = 3,
							name = "Show Header",
							type = "toggle",
						},
						framePosition = {
							order = 4,
							name = "Frame Position",
							type = "group",
							inline = true,
							args = {
								width = {
									order = 3,
									name = "Frame Width",
									type = "range",
									min = 64,
									max = 1024,
									step = 0.01,
									bigStep = 1,
									get = function(info)
										return C[info[2]][info[4]]
									end,
									set = function(info, value)
										C[info[2]][info[4]] = value
										Biddikus:UpdateFrame()
									end,
								},
								height = {
									order = 4,
									name = "Frame Height",
									type = "range",
									min = 10,
									max = 1024,
									step = 0.01,
									bigStep = 1,
									get = function(info)
										return C[info[2]][info[4]]
									end,
									set = function(info, value)
										C[info[2]][info[4]] = value
										Biddikus:UpdateFrame()
									end,
								},
								xOffset = {
									order = 5,
									name = "Frame xOffset",
									type = "range",
									softMin = 0,
									softMax = screenWidth,
									step = 0.01,
									bigStep = 1,
									get = function(info)
										return C[info[2]].position[4]
									end,
									set = function(info, value)
										C[info[2]].position[4] = value
										Biddikus:UpdateFrame()
									end,
								},
								yOffset = {
									order = 5,
									name = "Frame yOffset",
									type = "range",
									softMin = -screenHeight,
									softMax = 0,
									step = 0.01,
									bigStep = 1,
									get = function(info)
										return C[info[2]].position[5]
									end,
									set = function(info, value)
										C[info[2]].position[5] = value
										Biddikus:UpdateFrame()
									end,
								},
							},
						},
						scale = {
							order = 5,
							name = "Frame Scale",
							type = "range",
							min = 50,
							max = 300,
							step = 1,
							bigStep = 10,
							get = function(info)
								return C[info[2]][info[3]] * 100
							end,
							set = function(info, value)
								C[info[2]][info[3]] = value / 100
								Biddikus:UpdateFrame()
							end,
						},
						frameColors = {
							order = 6,
							name = "Color",
							type = "group",
							inline = true,
							get = function(info)
								return unpack(C[info[2]][info[4]])
							end,
							set = function(info, r, g, b, a)
								local cfg = C[info[2]][info[4]]
								cfg[1] = r
								cfg[2] = g
								cfg[3] = b
								cfg[4] = a
								Biddikus:UpdateFrame()
							end,

							args = {
								color = {
									order = 1,
									name = "Background Colour",
									type = "color",
									hasAlpha = true,
								},
								headerColor = {
									order = 2,
									name = "Header Colour",
									type = "color",
									hasAlpha = true,
								},
							},
						},
					},
				},
				bar = {
					order = 2,
					name = "Bar",
					type = "group",
                    inline = true,
					args = {
						height = {
							order = 3,
							name = "Bar Height",
							type = "range",
							min = 6,
							max = 64,
							step = 1,
                        },
					},
				},
				font = {
					order = 5,
					name = "Font",
					type = "group",
					inline = true,
					args = {
						size = {
							order = 2,
							name = "Font Size",
							type = "range",
							min = 6,
							max = 64,
							step = 1,
						},
						style = {
							order = 3,
							name = "Font Style",
							type = "select",
							values = {
								[""] = "NONE",
								["OUTLINE"] = "OUTLINE",
								["THICKOUTLINE"] = "THICKOUTLINE",
							},
							style = "dropdown",
						},
						name = {
							order = 4,
							name = "Font Name",
							type = "select",
							dialogControl = 'LSM30_Font',
							values = AceGUIWidgetLSMlists.font,
						},
						shadow = {
							order = 5,
							name = "Font Shadow",
							type = "toggle",
							width = "full",
						},
					},
				},
				reset = {
					order = 6,
					name = "Reset",
					type = "execute",
					func = function(info, value)
						Biddikus.db.profile = Biddikus.defaultOptions
						Biddikus:UpdateFrame()
					end,
				},
            },
        },
        sound = {
            order = 3,
            type = "group",
            name = "Sound",
			args = {
                enable = {
                    order = 1,
                    type = "toggle",
                    name = "Enable Sound",
                    desc = "Enable sounds",
                    get = function(info) return(Biddikus.db.profile.sound.enable) end,
                    set = function(info, key) Biddikus.db.profile.sound.enable=key end
                },
                start = {
                    order = 2,
                    type = "toggle",
                    name = "Enable Start",
                    desc = "Enable bid start notification",
                    get = function(info) return(Biddikus.db.profile.sound.start) end,
                    set = function(info, key) Biddikus.db.profile.sound.start=key end
                },
                countdown = {
                    order = 3,
                    type = "toggle",
                    name = "Enable Countdown",
                    desc = "Enable bid timeout countdown",
                    get = function(info) return(Biddikus.db.profile.sound.countdown) end,
                    set = function(info, key) Biddikus.db.profile.sound.countdown=key end
                },
                pause = {
                    order = 4,
                    type = "toggle",
                    name = "Enable Pause",
                    desc = "Enable bid pause notification",
                    get = function(info) return(Biddikus.db.profile.sound.pause) end,
                    set = function(info, key) Biddikus.db.profile.sound.pause=key end
                },
                resume = {
                    order = 5,
                    type = "toggle",
                    name = "Enable Resume",
                    desc = "Enable bid resume notification",
                    get = function(info) return(Biddikus.db.profile.sound.resume) end,
                    set = function(info, key) Biddikus.db.profile.sound.resume=key end
                },
                raidWarningSound = {
                    order = 6,
                    type = "toggle",
                    name = "Enable Raid Warning",
                    desc = "Enable Raid Warning sound",
                    get = function(info) return(Biddikus.db.profile.sound.raidWarningSound) end,
                    set = function(info, key) Biddikus.db.profile.sound.raidWarningSound=key end
                }
            }
        },
        masterlooter = {
            order = 4,
            type = "group",
            name = "Masterlooter",
			args = {
                bidTimeout = {
                    order = 1, 
                    type = "range",
                    min = 15,
                    max = 180,
                    step = 1,
                    name = "Bid Timeout",
                    desc = "Set the starting and maximum time on a bid timer",
                    get = function(info) return(Biddikus.db.profile.bidTimeout) end,
                    set = function(info, key) Biddikus.db.profile.bidTimeout=key end
                },
                bidMinimum = {
                    order = 2, 
                    type = "input",
                    name = "Minimum Bid",
                    desc = "Set the starting bid value",
                    get = function(info) 
                        Biddikus:UpdateFrame()
                        return(Biddikus.db.profile.bidMinimum)
                    end,
                    set = function(info, key) Biddikus.db.profile.bidMinimum=key end
                },
                postLoot = {
                    order = 3, 
                    type = "toggle",
                    name = "Post Loot",
                    desc = "Post looted items into raid chat",
                    get = function(info) return(Biddikus.db.profile.postLoot) end,
                    set = function(info, key) Biddikus.db.profile.postLoot=key end
                },
                qualityThreshold = {
                    order = 4, 
                    type = "range",
                    min = 0,
                    max = 8,
                    step = 1,
                    name = "Item Quality",
                    desc = "Set the item quality threshold for posting to raid chat",
                    get = function(info) return(Biddikus.db.profile.qualityThreshold) end,
                    set = function(info, key) Biddikus.db.profile.qualityThreshold=key end
                },
            }
        }
	}
}
Biddikus.defaultOptions = {
	profile = {
        enable = true,
        bidIncrement = 5,
        bidTimeout = 30,
        bidMinimum = 1,
        nickname = nil,
        flash = false,
        raidWarningStart = false,
        raidWarningEnd = false,
        autohide = false,
        postLoot = true,
        qualityThreshold = 4,
        sound = {
            enable = true,
            start = true,
            countdown = true,
            pause = true,
            resume = true,
            raidWarningSound = false,
        },
        frame = {
            scale				= 1,									-- global scale
            width				= 217,									-- frame width
            height				= 161,									-- frame height
            locked				= false,								-- toggle for movable
            strata				= "3-MEDIUM",							-- frame strata
            position			= {"TOPLEFT", "UIParent", "TOPLEFT", 50, -200},	-- frame position
            color				= {0, 0, 0, 0.35},						-- frame background color
            headerShow			= true,									-- show frame header
            headerColor			= {0, 0, 0, 0.8},						-- frame header color
            minHeight           = 18,
        },
        backdrop = {
            bgTexture			= defaultTexture,						-- backdrop texture
            bgColor				= {1, 1, 1, 0.1},						-- backdrop color
            edgeTexture			= defaultTexture,						-- backdrop edge texture
            edgeColor			= {0, 0, 0, 1},							-- backdrop edge color
            tile				= false,								-- backdrop texture tiling
            tileSize			= 0,									-- backdrop tile size
            edgeSize			= 1,									-- backdrop edge size
            inset				= 0,									-- backdrop inset value
        },
        font = {
            name 				= defaultFont,							-- font name
            size				= 12,									-- font size
            style				= "OUTLINE",							-- font style
            color				= {1, 1, 1, 1},							-- font color
            shadow				= true,									-- font dropshadow
        },
        bar = {
            height				= 18,									-- bar height
        }
    },
}

local LSM = LibStub("LibSharedMedia-3.0")
-- Register some media
LSM:Register("sound", "Priority1", [[Interface\AddOns\Biddikus\media\sound\priority1.ogg]])
LSM:Register("sound", "Priority2", [[Interface\AddOns\Biddikus\media\sound\priority2.ogg]])
LSM:Register("sound", "Priority3", [[Interface\AddOns\Biddikus\media\sound\priority3.ogg]])
LSM:Register("sound", "Priority4", [[Interface\AddOns\Biddikus\media\sound\priority4.ogg]])
LSM:Register("sound", "Priority5", [[Interface\AddOns\Biddikus\media\sound\priority5.ogg]])
LSM:Register("sound", "Priority6", [[Interface\AddOns\Biddikus\media\sound\bane1.ogg]])
LSM:Register("sound", "Priority7", [[Interface\AddOns\Biddikus\media\sound\bane2.ogg]])
LSM:Register("sound", "Priority8", [[Interface\AddOns\Biddikus\media\sound\bus1.ogg]])
LSM:Register("sound", "Priority9", [[Interface\AddOns\Biddikus\media\sound\bus2.ogg]])
LSM:Register("sound", "Priority10", [[Interface\AddOns\Biddikus\media\sound\dotskekw.ogg]])
LSM:Register("sound", "Priority11", [[Interface\AddOns\Biddikus\media\sound\dotswood.ogg]])
LSM:Register("sound", "Priority12", [[Interface\AddOns\Biddikus\media\sound\lim1.ogg]])
LSM:Register("sound", "Priority13", [[Interface\AddOns\Biddikus\media\sound\lisp1.ogg]])
LSM:Register("sound", "Priority14", [[Interface\AddOns\Biddikus\media\sound\tsbdotsdumb.ogg]])
LSM:Register("sound", "Priority15", [[Interface\AddOns\Biddikus\media\sound\xel1.ogg]])
LSM:Register("sound", "Priority16", [[Interface\AddOns\Biddikus\media\sound\xel2.ogg]])
LSM:Register("sound", "Priority17", [[Interface\AddOns\Biddikus\media\sound\xel3.ogg]])
LSM:Register("sound", "Priority18", [[Interface\AddOns\Biddikus\media\sound\xel4.ogg]])
LSM:Register("sound", "Priority19", [[Interface\AddOns\Biddikus\media\sound\xelglaives.ogg]])
LSM:Register("sound", "Priority20", [[Interface\AddOns\Biddikus\media\sound\xelgood.ogg]])
LSM:Register("sound", "Priority21", [[Interface\AddOns\Biddikus\media\sound\xelmagfault.ogg]])
LSM:Register("sound", "Priority22", [[Interface\AddOns\Biddikus\media\sound\xeltoken.ogg]])
LSM:Register("sound", "Priority23", [[Interface\AddOns\Biddikus\media\sound\xeltsbbop.ogg]])
LSM:Register("sound", "Priority24", [[Interface\AddOns\Biddikus\media\sound\casstupidgame.ogg]])
LSM:Register("sound", "Priority25", [[Interface\AddOns\Biddikus\media\sound\limstand.ogg]])
LSM:Register("sound", "Priority26", [[Interface\AddOns\Biddikus\media\sound\tsbbop2.ogg]])
LSM:Register("sound", "Priority27", [[Interface\AddOns\Biddikus\media\sound\xelbeaten.ogg]])
LSM:Register("sound", "Priority28", [[Interface\AddOns\Biddikus\media\sound\xelchicken.ogg]])
LSM:Register("sound", "Priority29", [[Interface\AddOns\Biddikus\media\sound\dotsdryballs.ogg]])
LSM:Register("sound", "Priority30", [[Interface\AddOns\Biddikus\media\sound\tsbyikes.ogg]])
LSM:Register("sound", "Priority31", [[Interface\AddOns\Biddikus\media\sound\xelsquawk.ogg]])
LSM:Register("sound", "Priority32", [[Interface\AddOns\Biddikus\media\sound\xelthesimp.ogg]])
LSM:Register("sound", "Priority33", [[Interface\AddOns\Biddikus\media\sound\xelwelldonehealies.ogg]])
LSM:Register("sound", "Priority34", [[Interface\AddOns\Biddikus\media\sound\casstoken.ogg]])
LSM:Register("sound", "Reset", [[Interface\AddOns\Biddikus\media\sound\reset.ogg]])
LSM:Register("sound", "Pause", [[Interface\AddOns\Biddikus\media\sound\pause.ogg]])
LSM:Register("sound", "1", [[Interface\AddOns\Biddikus\media\sound\Kolt\1.ogg]])
LSM:Register("sound", "2", [[Interface\AddOns\Biddikus\media\sound\Kolt\2.ogg]])
LSM:Register("sound", "3", [[Interface\AddOns\Biddikus\media\sound\Kolt\3.ogg]])
LSM:Register("sound", "4", [[Interface\AddOns\Biddikus\media\sound\Kolt\4.ogg]])
LSM:Register("sound", "5", [[Interface\AddOns\Biddikus\media\sound\Kolt\5.ogg]])
LSM:Register("font", "NotoSans SemiCondensedBold", [[Interface\AddOns\Biddikus\media\NotoSans-SemiCondensedBold.ttf]])
LSM:Register("font", "Standard Text Font", _G.STANDARD_TEXT_FONT) -- register so it's usable as a default in config
LSM:Register("statusbar", "Biddikus Default", [[Interface\ChatFrame\ChatFrameBackground]]) -- register so it's usable as a default in config

local SoundChannels = {
	["Master"] = "Master",
	["SFX"] =  "SFX",
	["Ambience"] =  "Ambience",
	["Music"] = "Music"
}

-----------------------------
-- Frame
-----------------------------
Biddikus.frame = CreateFrame("Frame", Biddikus.addonName.."Frame", UIParent)

local function UpdateFont(fs, size)
	fs:SetFont(LSM:Fetch("font", C.font.name), C.font.size - size, C.font.style)
	fs:SetVertexColor(unpack(C.font.color))
	fs:SetShadowOffset(C.font.shadow and 1 or 0, C.font.shadow and -1 or 0)
end

local function CreateFS(parent)
	local fs = parent:CreateFontString(nil, "ARTWORK")
	fs:SetFont(LSM:Fetch("font", C.font.name), C.font.size, C.font.style)
	return fs
end

local function SetPosition(f)
	local _, _, _, x, y = f:GetPoint()
	C.frame.position = {"TOPLEFT", "UIParent", "TOPLEFT", x, y}
end

local function OnDragStart(f)
	if not C.frame.locked then
		f = f:GetParent()
		f:StartMoving()
	end
end

local function OnDragStop(f)
	if not C.frame.locked then
		f = f:GetParent()
		-- make sure to call before StopMovingOrSizing, or frame anchors will be broken
		-- see https://wowwiki.fandom.com/wiki/API_Frame_StartMoving
		SetPosition(f)
		f:StopMovingOrSizing()

	end
end

local function UpdateSize(f)
	C.frame.width = f:GetWidth() - 2
	C.frame.height = f:GetHeight()

	Biddikus:UpdateFrame()
end

local function OnResizeStart(f)
	Biddikus.frame.header:SetMovable(false)
	f = f:GetParent()
	f:SetMinResize(64, C.bar.height)
	f:SetMaxResize(512, 1024)
	Biddikus.sizing = true
	f:SetScript("OnSizeChanged", UpdateSize)
	f:StartSizing()
end

local function OnResizeStop(f)
	Biddikus.frame.header:SetMovable(true)
	f = f:GetParent()
	Biddikus.sizing = false
	f:SetScript("OnSizeChanged", nil)
	f:StopMovingOrSizing()
end

function Biddikus:FlashScreen()
	if not self.FlashFrame then
		local flasher = CreateFrame("Frame", "BiddikusFlashFrame")
		flasher:SetToplevel(true)
		flasher:SetFrameStrata("FULLSCREEN_DIALOG")
		flasher:SetAllPoints(UIParent)
		flasher:EnableMouse(false)
		flasher:Hide()
		flasher.texture = flasher:CreateTexture(nil, "BACKGROUND")
		flasher.texture:SetTexture("Interface\\FullScreenTextures\\LowHealth")
		flasher.texture:SetAllPoints(UIParent)
		flasher.texture:SetBlendMode("ADD")
		flasher:SetScript("OnShow", function(self)
			self.elapsed = 0
			self:SetAlpha(0)
		end)
		flasher:SetScript("OnUpdate", function(self, elapsed)
			elapsed = self.elapsed + elapsed
			if elapsed < 2.6 then
				local alpha = elapsed % 1.3
				if alpha < 0.15 then
					self:SetAlpha(alpha / 0.15)
				elseif alpha < 0.9 then
					self:SetAlpha(1 - (alpha - 0.15) / 0.6)
				else
					self:SetAlpha(0)
				end
			else
				self:Hide()
			end
			self.elapsed = elapsed
		end)
		self.FlashFrame = flasher
	end

	self.FlashFrame:Show()
end

function Biddikus:UpdateFrame()
	local frame = self.frame

	if not Biddikus.sizing then
        frame:SetSize(C.frame.width + 2, C.frame.height)
	end
	frame:ClearAllPoints()
	frame:SetPoint(unpack(C.frame.position))
	frame:SetScale(C.frame.scale)
	frame:SetFrameStrata(strsub(C.frame.strata, 3))

    if not C.frame.locked then
		frame:SetMovable(true)
		frame:SetResizable(true)
		frame:SetClampedToScreen(true)

		frame.resize:Show()
		frame.resize:EnableMouse(true)
		frame.resize:SetMovable(true)
		frame.resize:RegisterForDrag("LeftButton")
		frame.resize:SetScript("OnDragStart", OnResizeStart)
		frame.resize:SetScript("OnDragStop", OnResizeStop)

		frame.header:SetMovable(true)
		frame.header:SetClampedToScreen(true)
		frame.header:RegisterForDrag("LeftButton")
		frame.header:SetScript("OnDragStart", OnDragStart)
		frame.header:SetScript("OnDragStop", OnDragStop)
    else
		frame:SetMovable(false)
		frame:SetResizable(false)
		frame.resize:Hide()
		frame.resize:SetMovable(false)
		frame.header:SetMovable(false)
	end

	-- Background
	frame.bg:SetAllPoints()
    frame.bg:SetVertexColor(unpack(C.frame.color))
    
    
    frame.itemcontainer:SetSize(C.frame.width, C.bar.height)
    frame.itemcontainer.item:SetSize(C.bar.height - 3, C.bar.height - 3)
    frame.itemcontainer.text:SetSize(C.frame.width - 3 - C.bar.height, C.bar.height - 3)
    frame.itemcontainer.timer:SetSize(C.frame.width - 3, C.bar.height - 3)
    frame.history:SetSize(C.frame.width - 6, C.frame.height - C.bar.height - (C.bar.height + 6))
    local bidcontainerOffset = 0
    if not C.frame.locked then
        bidcontainerOffset = 15
    else
        bidcontainerOffset = 0
    end
    frame.bidcontainer:SetSize(C.frame.width - bidcontainerOffset, C.bar.height)
    frame.bidbox:SetSize(C.frame.width * 2/3 - bidcontainerOffset - 6, C.bar.height)
    frame.bidbutton:SetSize(C.frame.width * 1/3 - 3, C.bar.height)

    frame.header.text:SetPoint("LEFT", frame.header, C.bar.height + 2, -1)
    frame.history:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -C.bar.height)
    frame.itemcontainer.text:SetPoint("LEFT", frame.itemcontainer, C.bar.height + 3, -1)
    frame.itemcontainer.timer:SetPoint("RIGHT", frame.itemcontainer, 0, -1)

    frame.history:SetFont(LSM:Fetch("font", C.font.name), C.font.size -2, C.font.style)
    frame.itemcontainer.text:SetFont(LSM:Fetch("font", C.font.name), C.font.size-1, C.font.style)
    frame.bidbox:SetFont(LSM:Fetch("font", C.font.name), C.font.size, C.font.style)

    frame.bidbutton:SetEnabled(false)

    frame.itemcontainer.timer:SetText(self.bid.timerCount)

    UpdateFont(frame.itemcontainer.text, -1)
    UpdateFont(frame.itemcontainer.timer, -1)

    if self.bid.timerCount then
        if self.bid.timerCount < 6 and self.bid.timerCount > 0 then
            frame.itemcontainer.timer:SetTextColor(1, 0, 0, 1)
        end
    end

    if Biddikus.bid.item then

        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(Biddikus.bid.item)
        frame.itemcontainer.text:SetText(itemName)
        if itemQuality then
            r, g, b = GetItemQualityColor(itemQuality)
            frame.itemcontainer.text:SetTextColor(r, g, b, 1)
        end
        frame.itemcontainer.item.texture:SetAllPoints()
        frame.itemcontainer.item.texture:SetTexture(itemTexture)

        Biddikus:SetBidAmount()

        if Biddikus.bid.state == "OPEN" then
            frame.bidbutton:SetEnabled(true)
        else
            frame.bidbutton:SetEnabled(false)
        end

        -- If you are winning, disable button
        if Biddikus.bid.currentPlayer == (C.nickname and C.nickname or self.playerName) then
            frame.bidbutton:SetEnabled(false)
        end
    end

    -- force clear bid box
    if Biddikus.bid.state == "CLOSED" then
        frame.bidbox:SetText("")
    end

	-- Header
    if C.frame.headerShow then
        frame.header.logo:SetSize(C.bar.height - 2, C.bar.height - 2)
        frame.header.text:SetSize(C.frame.width, C.bar.height)
        frame.header:SetSize(C.frame.width + 2, C.bar.height)

        frame.header:SetPoint("TOPLEFT", frame, 0, C.bar.height - 1)
        frame.header.text:SetPoint("LEFT", self.frame.header, C.bar.height + 2, -1)
	    frame.header.bg:SetAllPoints()
	    frame.header.bg:SetVertexColor(unpack(C.frame.headerColor))

        frame.header.text:SetText("Biddikus")

		UpdateFont(frame.header.text, 0)

		frame.header:Show()
	else
		frame.header:Hide()
    end

    -- Footer
    frame.footer:Hide()
    if self:CheckIfMasterLooter() then
        frame.footer:SetSize(C.frame.width + 2, C.bar.height*2 + 9)

		frame.footer:SetPoint("BOTTOMLEFT", frame, 0, -C.bar.height*2 - 9)
	    frame.footer.bg:SetAllPoints()
        frame.footer.bg:SetVertexColor(unpack(C.frame.color))

        frame.footer.text:SetSize(C.frame.width * 2/4 -3, C.bar.height)
        frame.footer.minbox:SetSize(C.frame.width * 1/4 -3, C.bar.height)
        frame.footer.startbutton:SetSize(C.frame.width * 1/4 -3, C.bar.height)

        frame.footer.text:SetFont(LSM:Fetch("font", C.font.name), C.font.size, C.font.style)
        frame.footer.minbox:SetFont(LSM:Fetch("font", C.font.name), C.font.size, C.font.style)

        frame.footer.pausebutton:SetSize(C.frame.width * 1/4 -3, C.bar.height)
        frame.footer.resumebutton:SetSize(C.frame.width * 1/4 -3, C.bar.height)
        frame.footer.endbutton:SetSize(C.frame.width * 1/4 -3, C.bar.height)
        frame.footer.clearbutton:SetSize(C.frame.width * 1/4 -3, C.bar.height)

        frame.footer.text:SetPoint("TOPLEFT", frame.footer, "TOPLEFT", 3, -3)
        frame.footer.minbox:SetPoint("TOPRIGHT", frame.footer, "TOPRIGHT", -(C.frame.width * 1/4 + 3), -3)
        frame.footer.startbutton:SetPoint("TOPRIGHT", frame.footer, "TOPRIGHT", -3, -3)
        frame.footer.pausebutton:SetPoint("BOTTOMLEFT", frame.footer, "BOTTOMLEFT", 3, 3)
        frame.footer.resumebutton:SetPoint("BOTTOMLEFT", frame.footer, "BOTTOMLEFT", (C.frame.width * 1/4 + 3), 3)
        frame.footer.endbutton:SetPoint("BOTTOMRIGHT", frame.footer, "BOTTOMRIGHT", -(C.frame.width * 1/4 + 3), 3)
        frame.footer.clearbutton:SetPoint("BOTTOMRIGHT", frame.footer, "BOTTOMRIGHT", -3, 3)

        frame.footer.minbox:SetNumber(string.format("%.2f", C.bidMinimum))

        if Biddikus.item then
            local itemName, itemLink, itemQual = GetItemInfo(Biddikus.item)
            frame.footer.text:SetText(itemName)
            r, g, b = GetItemQualityColor(itemQual)
            frame.footer.text:SetTextColor(r, g, b, 1)
        end

        if Biddikus.bid.state == "OPEN" then
            frame.footer.startbutton:SetEnabled(false)
        else
            frame.footer.startbutton:SetEnabled(true)
        end

        frame.footer:Show()
    else
        frame.footer:Hide()
    end

    if C.autohide and not Biddikus.bid.item then
        frame:SetSize(C.frame.width + 2, 1)
        if not Biddikus:CheckIfMasterLooter() then
            frame.header:Hide()
        end
        frame.bidcontainer:Hide()
        frame.itemcontainer:Hide()
        frame.bg:SetVertexColor(0, 0, 0, 0)
    else
        frame:SetSize(C.frame.width + 2, C.frame.height)
        frame.header:Show()
        frame.bidcontainer:Show()
        frame.itemcontainer:Show()
        frame.bg:SetVertexColor(unpack(C.frame.color))
    end

    if C.enable then
        frame:Show()
    else
        frame:Hide()
    end
end

local function CreateBackdrop(parent, cfg)
	local f = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
	f:SetPoint("TOPLEFT", parent, "TOPLEFT", -cfg.inset, cfg.inset)
	f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", cfg.inset, -cfg.inset)
	-- Backdrop Settings
	local backdrop = {
		edgeFile = LSM:Fetch("statusbar", cfg.edgeTexture),
		tile = cfg.tile,
		tileSize = cfg.tileSize,
		edgeSize = cfg.edgeSize,
		insets = {
			left = cfg.inset,
			right = cfg.inset,
			top = cfg.inset,
			bottom = cfg.inset,
		},
	}
	f:SetBackdrop(backdrop)
	f:SetBackdropColor(unpack(cfg.bgColor))
	f:SetBackdropBorderColor(unpack(cfg.edgeColor))

	parent.backdrop = f
end

-----------------------------
-- SETUP
-----------------------------
function Biddikus:SetupFrame()
	self.frame:SetFrameLevel(1)
	self.frame:ClearAllPoints()
	self.frame:SetPoint(unpack(C.frame.position))

	self.frame.bg = self.frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	self.frame.bg:SetColorTexture(1, 1, 1, 1)

	self.frame.resize = CreateFrame("Frame", self.addonName.."Resize", self.frame)
	self.frame.resize:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
	self.frame.resize:SetSize(12, 12)
	self.frame.resizeTexture = self.frame.resize:CreateTexture()
	self.frame.resizeTexture:SetTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
	self.frame.resizeTexture:SetDesaturated(true)
	self.frame.resizeTexture:SetPoint("TOPLEFT", self.frame.resize)
	self.frame.resizeTexture:SetPoint("BOTTOMRIGHT", self.frame.resize, "BOTTOMRIGHT", 0, 0)

	-- Setup Header
    self.frame.header = CreateFrame("Frame", nil, self.frame)
    CreateBackdrop(self.frame.header, C.backdrop)

	self.frame.header:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" then
			EasyMenu(Biddikus.menuTable, Biddikus.menu, "cursor", 0, 0, "MENU")
		end
	end)
	self.frame.header:EnableMouse(true)

	self.frame.header.text = CreateFS(self.frame.header)
    self.frame.header.text:SetJustifyH("LEFT")
    self.frame.header.bg = self.frame.header:CreateTexture(nil, "BACKGROUND", nil, -8)
    self.frame.header.bg:SetColorTexture(1, 1, 1, 1)

    self.frame.header.logo = CreateFrame("Frame", "ItemIcon", self.frame.header)
    self.frame.header.logo:SetPoint("LEFT", self.frame.header, 3, 0)
    self.frame.header.logo.texture = self.frame.header.logo:CreateTexture(nil, "ARTWORK")
    self.frame.header.logo.texture:SetAllPoints()
    self.frame.header.logo.texture:SetTexture([[Interface\AddOns\Biddikus\media\adtlogo.tga]], false)

    -- Setup Item Display
    self.frame.itemcontainer = CreateFrame("Frame", "ItemContainer", self.frame)
    self.frame.itemcontainer:SetPoint("TOP")

    self.frame.itemcontainer.item = CreateFrame("Frame", "ItemIcon", self.frame.itemcontainer)
    self.frame.itemcontainer.item:SetPoint("LEFT", self.frame.itemcontainer, 3, -1)
    self.frame.itemcontainer.item:EnableMouse(true)
    self.frame.itemcontainer.item.texture = self.frame.itemcontainer.item:CreateTexture(nil,"ARTWORK")
    self.frame.itemcontainer.item.texture:SetColorTexture(1, 1, 1, 1)

    self.frame.itemcontainer.text = CreateFS(self.frame.itemcontainer)
    self.frame.itemcontainer.text:SetPoint("LEFT", self.frame.itemcontainer, C.bar.height + 3, 0)
    self.frame.itemcontainer.text:SetJustifyH("LEFT")

    self.frame.itemcontainer.timer = CreateFS(self.frame.itemcontainer)
    self.frame.itemcontainer.timer:SetJustifyH("RIGHT")    
    
    -- Setup Bid History
    self.frame.history = CreateFrame("ScrollingMessageFrame", "BidHistory", self.frame)
    self.frame.history:SetJustifyH("LEFT")
    self.frame.history:SetFading(false)
    self.frame.history:SetInsertMode("BOTTOM")

    -- Setup Bidding
    self.frame.bidcontainer = CreateFrame("Frame", "BidContainer", self.frame)
    self.frame.bidcontainer:SetPoint("BOTTOMLEFT")

    self.frame.bidbox = CreateFrame("EditBox", "BidBox", self.frame.bidcontainer)
    self.frame.bidbox:SetPoint("LEFT", self.frame.bidcontainer, "LEFT", 3, 3)
    self.frame.bidbox:SetMovable(false)
    self.frame.bidbox:SetAutoFocus(false)
    self.frame.bidbox:SetMultiLine(false)
    self.frame.bidbox:SetScript("OnEnterPressed", EditBox_ClearFocus)
    self.frame.bidbox:SetScript("OnEscapePressed", EditBox_ClearFocus)
    self.frame.bidbox:SetScript("OnEditFocusLost", EditBox_ClearHighlight)
    self.frame.bidbox:SetScript("OnEditFocusGained", EditBox_HighlightText)

    CreateBackdrop(self.frame.bidbox, C.backdrop)

    self.frame.bidbutton = CreateFrame("Button", "BidButton", self.frame.bidcontainer)
    self.frame.bidbutton:SetPoint("RIGHT", self.frame.bidcontainer, "RIGHT", -3, 3)
    self.frame.bidbutton:SetText("Bid")
    self.frame.bidbutton:SetDisabledFontObject(GameFontDisable)
    self.frame.bidbutton:SetHighlightFontObject(GameFontHighlight)
    self.frame.bidbutton:SetNormalFontObject(GameFontNormal)
    self.frame.bidbutton:SetScript("OnClick", function(self, arg1)
        amount = Biddikus.frame.bidbox:GetNumber()
        if amount > 0 then
            Biddikus:SendBid(Biddikus.frame.bidbox:GetNumber())
        end
        Biddikus.frame.bidbox:ClearFocus()
    end)
    
    CreateBackdrop(self.frame.bidbutton, C.backdrop)

    -- Setup Masterloot Footer
    self.frame.footer = CreateFrame("Frame", nil, self.frame)

    self.frame.footer.bg = self.frame.footer:CreateTexture(nil, "BACKGROUND", nil, -8)
    self.frame.footer.bg:SetColorTexture(1, 1, 1, 1)

    self.frame.footer.text = CreateFS(self.frame.footer)
    self.frame.footer.text:SetJustifyH("LEFT")

    self.frame.footer.minbox = CreateFrame("EditBox", "MinBox", self.frame.footer)
    self.frame.footer.minbox:SetMovable(false)
    self.frame.footer.minbox:SetAutoFocus(false)
    self.frame.footer.minbox:SetMultiLine(false)
    self.frame.footer.minbox:SetScript("OnEnterPressed", EditBox_ClearFocus)
    self.frame.footer.minbox:SetScript("OnEscapePressed", EditBox_ClearFocus)
    self.frame.footer.minbox:SetScript("OnEditFocusLost", EditBox_ClearHighlight)
    self.frame.footer.minbox:SetScript("OnEditFocusGained", EditBox_HighlightText)
    self.frame.footer.minbox:SetNumber(string.format("%.2f", C.bidMinimum))
    CreateBackdrop(self.frame.footer.minbox, C.backdrop)

    self.frame.footer.startbutton = CreateFrame("Button", "StartButton", self.frame.footer)
    self.frame.footer.startbutton:SetText("Start")
    self.frame.footer.startbutton:SetDisabledFontObject(GameFontDisable)
    self.frame.footer.startbutton:SetHighlightFontObject(GameFontHighlight)
    self.frame.footer.startbutton:SetNormalFontObject(GameFontNormal)
    self.frame.footer.startbutton:SetScript("OnClick", function(self, arg1)
        Biddikus:SendStartBid(Biddikus.item, Biddikus.frame.footer.minbox:GetNumber(), C.bidTimeout)
    end)
    CreateBackdrop(self.frame.footer.startbutton, C.backdrop)

    self.frame.footer.pausebutton = CreateFrame("Button", "PauseButton", self.frame.footer)
    self.frame.footer.pausebutton:SetText("Pause")
    self.frame.footer.pausebutton:SetDisabledFontObject(GameFontDisable)
    self.frame.footer.pausebutton:SetHighlightFontObject(GameFontHighlight)
    self.frame.footer.pausebutton:SetNormalFontObject(GameFontNormal)
    self.frame.footer.pausebutton:SetScript("OnClick", function(self, arg1)
        Biddikus:SendPauseBid()
    end)
    CreateBackdrop(self.frame.footer.pausebutton, C.backdrop)

    self.frame.footer.resumebutton = CreateFrame("Button", "ResumeButton", self.frame.footer)
    self.frame.footer.resumebutton:SetText("Resume")
    self.frame.footer.resumebutton:SetDisabledFontObject(GameFontDisable)
    self.frame.footer.resumebutton:SetHighlightFontObject(GameFontHighlight)
    self.frame.footer.resumebutton:SetNormalFontObject(GameFontNormal)
    self.frame.footer.resumebutton:SetScript("OnClick", function(self, arg1)
        Biddikus:SendUnpauseBid()
    end)
    CreateBackdrop(self.frame.footer.resumebutton, C.backdrop)

    self.frame.footer.endbutton = CreateFrame("Button", "EndButton", self.frame.footer)
    self.frame.footer.endbutton:SetText("End")
    self.frame.footer.endbutton:SetDisabledFontObject(GameFontDisable)
    self.frame.footer.endbutton:SetHighlightFontObject(GameFontHighlight)
    self.frame.footer.endbutton:SetNormalFontObject(GameFontNormal)
    self.frame.footer.endbutton:SetScript("OnClick", function(self, arg1)
        Biddikus:SendEndBid()
    end)
    CreateBackdrop(self.frame.footer.endbutton, C.backdrop)

    self.frame.footer.clearbutton = CreateFrame("Button", "ClearButton", self.frame.footer)
    self.frame.footer.clearbutton:SetText("Clear")
    self.frame.footer.clearbutton:SetDisabledFontObject(GameFontDisable)
    self.frame.footer.clearbutton:SetHighlightFontObject(GameFontHighlight)
    self.frame.footer.clearbutton:SetNormalFontObject(GameFontNormal)
    self.frame.footer.clearbutton:SetScript("OnClick", function(self, arg1)
        Biddikus:SendClearBid()
    end)
    CreateBackdrop(self.frame.footer.clearbutton, C.backdrop)

    if not self:CheckIfMasterLooter() then
        self.frame.footer:Hide()
    end

    self.frame.itemcontainer.item:HookScript("OnEnter", function()
        if Biddikus.bid.item then
            GameTooltip:SetOwner(Biddikus.frame, "ANCHOR_TOP")
            GameTooltip:SetHyperlink(Biddikus.bid.item)
            GameTooltip:Show()
        end
    end)
       
    self.frame.itemcontainer.item:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

	self:UpdateFrame()
end

function Biddikus:SetupMenu()
	self.menu = CreateFrame("Frame", self.addonName.."MenuFrame", UIParent, "UIDropDownMenuTemplate")

	Biddikus.menuTable = {
        {text = "Lock", notCheckable = false, checked = function() return C.frame.locked end, func = function()
            C.frame.locked = not C.frame.locked
			Biddikus:UpdateFrame()
		end},
		{text = "Configuration", notCheckable = true, func = function()
			LibStub("AceConfigDialog-3.0"):Open("Biddikus")
		end},
	}
end

-----------------------------
-- Events
-----------------------------
function Biddikus:OnInitialize() 
    Biddikus:RegisterEvent("PLAYER_LOGIN")
	initialized = true
end

  function Biddikus:OnEnable()
    if not initialized then self:OnInitialize() end

    Biddikus:RegisterEvent("LOOT_OPENED")
    Biddikus:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function Biddikus:OnDisable()
    Biddikus:UnregisterEvent("PLAYER_LOGIN")
    Biddikus:UnregisterEvent("LOOT_OPENED")
    Biddikus:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

function Biddikus:PLAYER_LOGIN()
    self.db = LibStub("AceDB-3.0"):New("BiddikusDB", self.defaultOptions)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Biddikus", self.options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Biddikus", "Biddikus")

    C = self.db.profile

    self.playerName = UnitName("player")

    self:SetupFrame()
	self:SetupMenu()

	self:RegisterChatCommand("biddikus", "ChatCommand")

    if C.welcome then
        print("|c008CB84F"..self.addonName.." v"..self.version.." - "..self.message_welcome.."|r")
    end

    self:UnregisterAllComm()
	self:RegisterComm(Biddikus.prefix)

    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

function Biddikus:LOOT_OPENED()
    if C.enable then
        if IsInRaid() then
           if self:CheckIfMasterLooter() then
                Biddikus:ListLoot()
           end
        end
    end
end

function Biddikus:GROUP_ROSTER_UPDATE()
    if C.enable then
        if IsInRaid() then
            lootMethod, masterLooterPartyID, masterLooterRaidID = GetLootMethod()
            if lootMethod == "master" then
                self.masterLooterName = GetRaidRosterInfo(masterLooterRaidID);
            else 
                self.masterLooterName = nil
            end
        else
            self.masterLooterName = nil
        end
        self:UpdateFrame()
    end
end

-----------------------------
-- Comms
-----------------------------

function Biddikus:SendComm(data)
    self:SendCommMessage(self.prefix, self:Serialize(data), "RAID")
end

function Biddikus:SendBid(amount)
    if self.bid.state == "OPEN" then
        if self:ValidateBid(amount) then
            localized, englishClass = UnitClass(self.playerName)
            payload = {
                messageType = "BID",
                playerName = self.playerName,
                playerNick = C.nickname and C.nickname or self.playerName, 
                playerClass = englishClass,
                bidAmount = amount,
            }
            self:SendComm(payload)
        else
            self:SetBidAmount()
        end
    end
end

function Biddikus:SendStartBid(item, minimum, timer)
    if self:CheckIfMasterLooter() then
        payload = {
            messageType = "START",
            item = item,
            minimum = minimum,
            timer = timer,
            rand = math.random(1,34)
        }
        self:SendComm(payload)
        SendChatMessage("[Biddikus] bid for " .. item .. " starting!", "RAID")
    end
end

function Biddikus:SendEndBid()
    if self:CheckIfMasterLooter() then
        payload = {
            messageType = "END",
            playerName = self.bid.currentPlayer,
            playerNick = self.bid.currentPlayerNick,
            playerClass = self.bid.currentClass,
            bidAmount = self.bid.currentBid
        }
        self:SendComm(payload)
    end
end
function Biddikus:SendPauseBid()
    if self:CheckIfMasterLooter() then
        payload = {
            messageType = "PAUSE"
        }
        self:SendComm(payload)
    end
end

function Biddikus:SendUnpauseBid()
    if self:CheckIfMasterLooter() then
        payload = {
            messageType = "UNPAUSE"
        }
        self:SendComm(payload)
    end
end

function Biddikus:SendClearBid()
    if self:CheckIfMasterLooter() then
        payload = {
            messageType = "CLEAR"
        }
        self:SendComm(payload)
    end
end

function Biddikus:OnCommReceived(prefix, message, distribution, sender)
    if (prefix == Biddikus.prefix and distribution == "RAID") then
        local success, payload = Biddikus:Deserialize(message)
        if not success then
            print("Deserialization Error")
            return
        end
        if payload.messageType == "BID" then
            self:ProcessBid(payload.playerName, payload.playerNick, payload.playerClass, payload.bidAmount)
        end
        if payload.messageType == "START" then
            self:SetupBid(payload.item, payload.minimum, payload.timer, payload.rand)
        end
        if payload.messageType == "END" then
            self:EndBid(payload.playerName, payload.playerNick, payload.playerClass, payload.bidAmount)
        end
        if payload.messageType == "PAUSE" then
            self:PauseBid()
        end
        if payload.messageType == "UNPAUSE" then
            self:UnpauseBid()
        end
        if payload.messageType == "CLEAR" then
            self:ClearBid()
        end
        self:UpdateFrame()
    end
end

-----------------------------
-- Functions
-----------------------------

function Biddikus:SetBidAmount()
    if Biddikus.bid.currentBid then
        if not Biddikus.frame.bidbox:HasFocus() then
            typedBid = Biddikus.frame.bidbox:GetNumber()
            if typedBid <= Biddikus.bid.currentBid then
                Biddikus.frame.bidbox:SetNumber(string.format("%.2f", Biddikus.bid.currentBid + C.bidIncrement))
            end
        end
    else 
        if not Biddikus.frame.bidbox:HasFocus() then
            typedBid = Biddikus.frame.bidbox:GetNumber()
            if typedBid <= Biddikus.bid.minimum then
                Biddikus.frame.bidbox:SetNumber(string.format("%.2f", Biddikus.bid.minimum))
            end
        end
    end
end

function Biddikus:ProcessBid(player, playerNick, class, amount)
    if self:ValidateBid(amount) then
        r, g, b = GetClassColor(class)
        self.frame.history:AddMessage(string.format("%.2f", amount) .. " - " .. playerNick, r, g, b)
        self.bid.currentBid = amount
        self.bid.currentPlayer = player
        self.bid.currentPlayerNick = playerNick
        self.bid.currentClass = class
        self.bid.timerCount = self.bid.timerCount + 10
        if self.bid.timerCount > self.bid.timerMax then
            self.bid.timerCount = self.bid.timerMax
        end
        self:SetBidAmount()
    end
end

function Biddikus:ValidateBid(amount)
    if self.bid.state == "OPEN" then
        if self.bid.currentBid == nil then
            if amount >= self.bid.minimum then
                return true
            end
        else 
            if amount > self.bid.currentBid then
                return true
            end
        end
    end
    return false
end

function Biddikus:SetupBid(item, minimum, timer, rand)
    if item then
        if C.sound.enable and C.sound.start then PlaySoundFile(LSM:Fetch("sound", "Priority" .. rand), "Master") end
        if C.raidWarningStart then
            RaidNotice_AddMessage(RaidWarningFrame, "[Biddikus] " .. item .. " starting!", ChatTypeInfo["RAID_WARNING"]);
        end
        if C.sound.raidWarningSound then
            PlaySound(8959, "Master");
        end        
        self.bid = {
            item = item,
            minimum = minimum,
            state = "OPEN",
            timer = self:ScheduleRepeatingTimer("CountdownTracker", 1),
            timerCount = timer,
            timerMax = timer,
            currentBid = nil,
            currentPlayer = nil,
            currentClass = nil,
        }
        self.frame.history:Clear()
        if Biddikus.frame.bidbox:GetNumber() < self.bid.minimum then
            Biddikus.frame.bidbox:SetNumber(string.format("%.2f", self.bid.minimum))
        end
    end
end

function Biddikus:EndBid(player, playerNick, class, amount)
    if self.bid.state then
        self.bid.state = "CLOSED"
        self.bid.currentBid = amount
        self.bid.currentPlayer = player
        self.bid.currentPlayerNick = playerNick
        self.bid.currentClass = class
        self:CancelTimer(self.bid.timer)
        self.bid.timerCount = nil
        self.bid.timerMax = nil
        if self.bid.currentPlayer then
            self.frame.history:AddMessage("Sold! Congratulations " .. playerNick .. ".")
            if self:CheckIfMasterLooter() then
                SendChatMessage("[Biddikus] " .. self.bid.item .. " sold to " .. player .. " for " .. string.format("%.2f", amount) .."dkp.  Congratulations!", "RAID")
            end
        else
            self.frame.history:AddMessage(self.bid.item .. " is unwanted.  So sad..")
            if self:CheckIfMasterLooter() then
                SendChatMessage("[Biddikus] " .. self.bid.item .. " has rotted.", "RAID")
            end
        end
    end
    self.frame.bidbox:SetText("")
    self:UpdateFrame()
end

function Biddikus:PauseBid()
    if self.bid.state == "OPEN" then
        if C.sound.enable and C.sound.pause then PlaySoundFile(LSM:Fetch("sound", "Pause"), "Master") end
        self.bid.state = "PAUSED"
        self.frame.history:AddMessage("Pausing bidding...")
        self:CancelTimer(self.bid.timer)
    end
end

function Biddikus:UnpauseBid()
    if self.bid.state == "PAUSED" then
        if C.sound.enable and C.sound.resume then PlaySoundFile(LSM:Fetch("sound", "Reset"), "Master") end
        self.bid.state = "OPEN"
        self.frame.history:AddMessage("Resuming bidding...")
        self.bid.timer = self:ScheduleRepeatingTimer("CountdownTracker", 1)
    end
end

function Biddikus:ClearBid()
    self.bid = {
        item = nil,
        minimum = nil,
        state = nil,
        timer = self:CancelTimer(self.bid.timer),
        timerCount = nil,
        timerMax = nil,
        currentBid = nil,
        currentPlayer = nil,
        currentClass = nil,
    }
    self.frame.itemcontainer.text:SetText("")
    self.frame.footer.text:SetText("")
    self.item = nil
    self.frame.bidbox:SetText("")
    self.frame.history:Clear()
    self.frame.itemcontainer.item.texture:SetTexture("")
    self.frame.itemcontainer.timer:SetText("")
    self:UpdateFrame()
end

function Biddikus:CountdownTracker()
    if self.bid.timerCount then
        self.bid.timerCount = self.bid.timerCount - 1

        if self.bid.timerCount < 6 and self.bid.timerCount > 0 then
            if C.sound.enable and C.sound.countdown then PlaySoundFile(LSM:Fetch("sound", tostring(self.bid.timerCount)), "Master") end
            if C.raidWarningEnd then
                RaidNotice_AddMessage(RaidWarningFrame, "[Biddikus] Ending in " .. tostring(self.bid.timerCount) .. "!", ChatTypeInfo["RAID_WARNING"]);
            end
            if C.sound.raidWarningSound then
                PlaySound(8959, "Master");
            end
            self.frame.history:AddMessage(self.bid.timerCount, 1, 0, 0)
            if C.flash then
                self:FlashScreen()
            end
        end
    end 

    if self.bid.timerCount == 0 then
        if self:CheckIfMasterLooter() then
            self:SendEndBid()
        end
        self.bid.timerCount = nil
        self:CancelTimer(self.bid.timer)
    end
    self:UpdateFrame()

end


function Biddikus:CheckIfMasterLooter()
    if self.playerName == self.masterLooterName then
        return true
    end
	return false
end


-- Check Rarity
-- Checks if Epic or Legendary
function Biddikus:CheckRarity(item)
    if item then
        local itemName, itemLink, itemQual = GetItemInfo(item)
        if (itemQual >= C.qualityThreshold) then
            return true
        end
    end
    return false
end

-- LIST_LOOT
-- This iterates through the items in an open loot window and lists them in raid chat
-- may change this to list items in window
function Biddikus:ListLoot()
    if C.postLoot then
        for i=1, GetNumLootItems() do
            local itemLink=GetLootSlotLink(i)
            if self:CheckRarity(itemLink) then
                i = i + 1
                SendChatMessage("[Biddikus] " .. itemLink, "RAID")
            end
        end
    end
end

function Biddikus:ChatCommand()
    LibStub("AceConfigDialog-3.0"):Open("Biddikus")
end

-- Shift click item in bag
hooksecurefunc("ContainerFrameItemButton_OnModifiedClick",function(self,button)
    local bag,slot=self:GetParent():GetID(),self:GetID();
    item = GetContainerItemLink(bag, slot)
    Biddikus.item = item
    Biddikus:UpdateFrame()
end);
