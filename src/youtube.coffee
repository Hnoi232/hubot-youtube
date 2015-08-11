# Description:
#   YouTube video search
#
# Configuration:
#   HUBOT_YOUTUBE_API_KEY - Obtained from https://console.developers.google.com
#   HUBOT_YOUTUBE_DETERMINISTIC_RESULTS - Optional boolean flag to only fetch
#     the top result from the YouTube search
#
# Commands:
#   hubot youtube me <query> - Searches YouTube for the query and returns the video embed link.
module.exports = (robot) ->
  robot.respond /(?:youtube|yt)(?: me)? (.*)/i, (msg) ->
    unless process.env.HUBOT_YOUTUBE_API_KEY
      robot.logger.error 'HUBOT_YOUTUBE_API_KEY is not set.'
      return msg.send "You must configure the HUBOT_YOUTUBE_API_KEY environment variable"
    query = msg.match[1]
    robot.logger.debug query
    maxResults = if process.env.HUBOT_YOUTUBE_DETERMINISTIC_RESULTS == 'true' then 1 else 15
    robot.logger.debug maxResults
    robot.http("https://www.googleapis.com/youtube/v3/search")
      .query({
        order: 'relevance'
        part: 'snippet'
        type: 'video'
        maxResults: maxResults
        q: query
        key: process.env.HUBOT_YOUTUBE_API_KEY
      })
      .get() (err, res, body) ->
        robot.logger.debug body
        if err
          robot.logger.error err
          return msg.send err
        try
          videos = JSON.parse(body)
        catch error
          robot.logger.error error
          return msg.send "Error! #{body}"
        if videos.error
          robot.logger.error videos.error
          return msg.send "Error! #{JSON.stringify(videos.error)}"
        robot.logger.debug videos
        videos = videos.items
        unless videos? && videos.length > 0
          return msg.send "No video results for \"#{query}\""
        video = msg.random videos
        msg.send "https://www.youtube.com/watch?v=#{video.id.videoId}"
