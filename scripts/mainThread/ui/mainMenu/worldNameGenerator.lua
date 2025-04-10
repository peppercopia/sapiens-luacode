local rng = mjrequire "common/randomNumberGenerator"

local worldNameGenerator = {}

local baseSeed = rng:integerForSeed(os.time() % 1000000, 124671)

local nouns = {
    "ale",
    "esun",
    "insa",
    "kala",
    "kasi",
    "kili",
    "kiwen",
    "ko",
    "kulupu",
    "lukin",
    "ma",
    "mama",
    "meli",
    "mije",
    "mun",
    "nasin",
    "nena",
    "pilin",
    "poki",
    "sike",
    "suno",
    "telo",
}

local adjectives = {
    "ale",
    "ante",
    "awen",
    "kama",
    "kule",
    "lape",
    "laso",
    "lete",
    "musi",
    "mute",
    "nasa",
    "pini",
    "pona",
    "seli",
    "sewi",
    "sin",
    "namako",
    "suli",
    "suwi",
    "tawa",
    "wawa",
}

function worldNameGenerator:getRandomName()
    baseSeed = baseSeed + 1
    local nounIndex = rng:integerForSeed(baseSeed, #nouns) + 1

    local name = nouns[nounIndex]

    baseSeed = baseSeed + 1
    if rng:integerForSeed(baseSeed, 4) < 3 then
        baseSeed = baseSeed + 1
        local adjectiveIndex = rng:integerForSeed(baseSeed, #adjectives) + 1
        name = name .. " " .. adjectives[adjectiveIndex]
        
        if rng:integerForSeed(baseSeed, 4) == 0 then
            baseSeed = baseSeed + 1
            local adjectiveIndexB = rng:integerForSeed(baseSeed, #adjectives) + 1
            name = name .. " " .. adjectives[adjectiveIndexB]
        end
    end

    return mj:capitalize(name)
end

return worldNameGenerator