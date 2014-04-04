# Description:
#   Twitch Public API
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot ttv game <category> - Returns the first 5 live streams in a game <category> (case-sensitive)
#   hubot ttv featured - Returns the first 5 featured live streams
#   hubot ttv stream <name> - Returns information about stream <name>
#   hubot ttv search <query> - Returns a list of live streams matching the search <query>
#
# Author:
#   MrSaints
#   mbwkarl
#
# Todo:
# - Save favourites?
#

module.exports = (robot) ->
    robot.respond /ttv game (.*)/i, (msg) ->
        category = msg.match[1]
        twitch_request msg, '/streams', { game: category, limit: 5 }, (object) ->
            if object._total is 0
                msg.reply "No live streams were found in \"#{category}\". Try a different category or try again later."
                return

            for stream in object.streams
                channel = stream.channel
                msg.send "#{channel.display_name} (\"#{channel.status}\") - #{channel.url} [Viewers: #{stream.viewers}]"

            if object._total > 5
                msg.reply "There are #{object._total - 5} other \"#{category}\" live streams."

    robot.respond /ttv featured/i, (msg) ->
        twitch_request msg, '/streams/featured', { limit: 5 }, (object) ->
            for feature in object.featured
                channel = feature.stream.channel
                msg.send "#{feature.stream.game}: #{channel.display_name} (#{channel.status}) - #{channel.url} [Viewers: #{feature.stream.viewers}]"

    robot.respond /ttv stream (.*)/i, (msg) ->
        twitch_request msg, "/streams/#{msg.match[1]}", null, (object) ->
            if object.status is 404
                msg.reply "The stream you have entered (\"#{msg.match[1]}\") does not exist."
                return

            if not object.stream
                msg.reply "The stream you have entered (\"#{msg.match[1]}\") is currently offline."
                return

            channel = object.stream.channel
            msg.send "#{channel.display_name} is streaming #{channel.game} @ #{channel.url}"
            msg.send "Stream status: \"#{channel.status}\""
            msg.send "Viewers: #{object.stream.viewers}"

twitch_request = (msg, api, params = {}, handler) ->
    msg.http("https://api.twitch.tv/kraken#{api}")
        .query(params)
        .get() (err, res, body) ->
            if err
                msg.reply "An error occurred while attempting to process your request: #{err}"
                return

            handler JSON.parse(body)