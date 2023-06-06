-----------------------------------------------------------------------
-- Modules
-----------------------------------------------------------------------
local FFAPI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/FFAPI.lua', true))()
local Enviroment = loadstring(game:HttpGet('https://raw.githubusercontent.com/Supermrk/FusionAPI/main/src/Modules/Utilities.lua', true))()

-----------------------------------------------------------------------
-- Final
-----------------------------------------------------------------------
local awayInfo = {
    City = "Minnesota",
    Name = "Vikings",
    Abbreviation = "MIN",
    Colors = {
        Normal = {
            Main = "#4F2E84",
            Light = "#4F2E84"
        },
        Alternate = {
            Main = "#FEC62F",
            Light = "#FEC62F"
        },
        Endzone = "#4F2E84",
        Jersey = {
            Home = {
                NumberInner = "#FFFFFF",
                NumberStroke = "#FFFFFF",
                Helmet = "#4F2E84",
                Jersey = "#4F2E84",
                Stripe = "#FEC62F",
                Pants = "#FFFFFF"
            },
            Away = {
                NumberInner = "#4F2E84",
                NumberStroke = "#4F2E84",
                Helmet = "#4F2E84",
                Jersey = "#FFFFFF",
                Stripe = "#FEC62F",
                Pants = "#4F2E84"
            }
        }
    }
}

local homeInfo = {
    City = "New Orleans",
    Name = "Saints",
    Abbreviation = "NO",
    Colors = {
        Normal = {
            Main = "#D3BC8D",
            Light = "#D3BC8D"
        },
        Alternate = {
            Main = "#000000",
            Light = "#000000"
        },
        Endzone = "#D3BC8D",
        Jersey = {
            Home = {
                NumberInner = "#D3BC8D",
                NumberStroke = "#FFFFFF",
                Helmet = "#D3BC8D",
                Jersey = "#000000",
                Stripe = "#D3BC8D",
                Pants = "#000000"
            },
            Away = {
                NumberInner = "#000000",
                NumberStroke = "#D3BC8D",
                Helmet = "#D3BC8D",
                Jersey = "#FFFFFF",
                Stripe = "#FFFFFF",
                Pants = "#FFFFFF"
            }
        }
    }
}

-----------------------------------------------------------------------
-- Setup
-----------------------------------------------------------------------
FFAPI.Settings.AwayTeam = awayInfo
FFAPI.Settings.HomeTeam = homeInfo
Enviroment:SetTeams(awayInfo,homeInfo)

--TODO Do rest of logic below: