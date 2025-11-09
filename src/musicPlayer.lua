local musicPlayer = {
  isPaused = false,
  fadeInTween = nil,
  fadeOutTween = nil,

  currentTrackIndex = 0,
  currentSource = nil,
  currentAssetKey = nil,
  targetVolume = 0,

  hasStarted = false,
}

local FADE_TIME = 3 -- seconds
local FADE_TIME_PAUSE = 1-- seconds
local FADE_BUFFER = 0.1 -- seconds

local flux = require("libs.flux")
local audioManager = require("util.audioManager")

musicPlayer.music = {
  "audio.music.fall",
  "audio.music.roundabout",
}

local clearTweens = function()
  if musicPlayer.fadeInTween then
    musicPlayer.fadeInTween:stop()
    musicPlayer.fadeInTween = nil
  end
  if musicPlayer.fadeOutTween then
    musicPlayer.fadeOutTween:stop()
    musicPlayer.fadeOutTween = nil
  end
end

local startFadeOut = function(onCompleteCallback, keepSource, fadeTime)
  clearTweens()

  if not musicPlayer.currentSource then
    if onCompleteCallback then
      onCompleteCallback()
    end
    logger.info("StartFadeOut on empty source, skipping to next")
    return
  end

  local sourceToFade = musicPlayer.currentSource
  local startVolume = sourceToFade:getVolume()

  local fade = { t = 1 }
  local fadeDuration = fadeTime
  if musicPlayer.targetVolume > 0 then
    fadeDuration = fadeTime * (startVolume / musicPlayer.targetVolume)
  end

  musicPlayer.fadeOutTween = flux.to(fade, fadeDuration, { t = 0 })
    :onupdate(function()
        if sourceToFade then
          sourceToFade:setVolume(startVolume * fade.t)
        end
      end)
    :oncomplete(function()
        musicPlayer.fadeOutTween = nil
        if sourceToFade then
          sourceToFade:stop()
          sourceToFade:seek(0)
        end
        if not keepSource then
          if musicPlayer.currentSource == sourceToFade then
            musicPlayer.currentSource = nil
            musicPlayer.currentAssetKey = nil
            musicPlayer.targetVolume = 0
          end
        end
        if onCompleteCallback then
          onCompleteCallback()
        end
      end)

end

local startFadeIn = function(assetKey, fadeTime)
  clearTweens()

  musicPlayer.currentAssetKey = assetKey
  musicPlayer.currentSource = audioManager.get(musicPlayer.currentAssetKey)
  musicPlayer.currentSource:play()
  musicPlayer.currentSource:setLooping(false)
  musicPlayer.currentSource:setVolume(0)
  musicPlayer.targetVolume = audioManager.getVolume(musicPlayer.currentAssetKey)

  local sourceToFade = musicPlayer.currentSource
  local endVolume = musicPlayer.targetVolume

  local fade = { t = 0 }
  musicPlayer.fadeInTween = flux.to(fade, fadeTime, { t = 1 })
    :onupdate(function()
        if sourceToFade then
          sourceToFade:setVolume(endVolume * fade.t)
        end
      end)
      :oncomplete(function()
        musicPlayer.fadeInTween = nil
      end)
end

local startNextTrackFadeIn = function(fadeTime)
  if musicPlayer.isPaused then
    return
  end
  fadeTime = fadeTime or FADE_TIME

  musicPlayer.currentTrackIndex = musicPlayer.currentTrackIndex % #musicPlayer.music + 1
  local nextAssetKey = musicPlayer.music[musicPlayer.currentTrackIndex]

  startFadeIn(nextAssetKey, fadeTime)
end

musicPlayer.start = function()
  if musicPlayer.hasStarted then
    return -- Already started
  end
  musicPlayer.hasStarted = true

  musicPlayer.isPaused = false
  musicPlayer.currentTrackIndex = 0

  musicPlayer.currentSource = nil

  startNextTrackFadeIn(FADE_TIME)
end

musicPlayer.update = function()
  if musicPlayer.isPaused then
    return
  end

  -- If stable state: no tweens, just playing
  if not musicPlayer.fadeInTween and not musicPlayer.fadeOutTween and musicPlayer.currentSource then
    local source = musicPlayer.currentSource
    if not source:isLooping() then
      local duration = source:getDuration()
      local currentTime = source:tell("seconds")

      -- Check if it is time to fade out
      if (duration - currentTime) <= (FADE_TIME + FADE_BUFFER) then
        startFadeOut(startNextTrackFadeIn, false, FADE_TIME)
      end
    end
  end
end

musicPlayer.pause = function()
  if not musicPlayer.hasStarted then
    return -- not initialised
  end
  if musicPlayer.isPaused then
    return -- already paused
  end
  musicPlayer.isPaused = true
  startFadeOut(nil, true, FADE_TIME_PAUSE)
end

musicPlayer.continue = function()
  if not musicPlayer.hasStarted then
    return -- not initialised
  end
  if not musicPlayer.isPaused then
    return -- already playing
  end
  musicPlayer.isPaused = false

  if not musicPlayer.currentSource or not musicPlayer.currentAssetKey then
    startNextTrackFadeIn(FADE_TIME_PAUSE)
  else
    startFadeIn(musicPlayer.currentAssetKey, FADE_TIME_PAUSE)
  end
end 

return musicPlayer