require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'
require 'uri'
require 'net/http'
require 'net/https'

SLACK_RTM_URL="https://slack.com/api/rtm.start"
SLACK_REACTION_URL="https://slack.com/api/reactions.get"

response = HTTP.post(SLACK_RTM_URL, params: {
    token: ENV['SLACK_API_TOKEN']
})

rc = JSON.parse(response.body)
url = rc['url']

EM.run do
    ws = Faye::WebSocket::Client.new(url)
    ws.on :open do
        p [:open]
    end

    ws.on :message do |event|
        data = JSON.parse(event.data)
        p [:message, data]
        if data['text'] == '疲れた'
            ws.send({
                type: 'message',
                text: "お疲れ様です! <@#{data['user']}>"
                channel: data['channel']
            }.to_json)
        elsif data['text'] == ':github_issue'
            ws.send({
                type: 'message',
                text: "<@#{data['user']}>さん！メッセージです"
                channel: data['channel']
            }.to_json)
        elsif data['text'] == 'ぐっときた'
            s.send({
                type: 'message',
                text: "<@#{data['user']}>さん！最高かよ"
                channel: data['channel']
            }.to_json)
        end

        if data['reation'] == 'github_issue'
            slack_response = HTTP.post(SLACK_REACTION_URL, params: {
                    token: ENV['SLACK_API_TOKEN'],
                    channel: data['item']['channel'],
                    timestamp: data['item']['ts']
                })
            slack_responce = JSON.parse(slack_responce)
            https = Net::HTTP.new('api.github.com', '443')
            https.use_ssl = true
            https.start do |https|
                req = Net::HTTP::Post.new('/repos/nagipan777/ruby_slack_bot/issues')
                req.basic_auth ENV['GITHUB_USERNAME'],ENV['GITHUB_PASSWORD']
                issue_info = {
                    'title': "#{slack_response['message']["text"]}",
                'body': "ヘルプです",
                "labels": [
                        "help wanted"
                    ]
                }
                req.body = JSON.generate issue_info
                github_response = https.request(req)

                github_response = JSON.parse(github_response.body)

                ws.send({
                    type: 'message',
                    text: "<@#{data['user']}> さんのために、issueを作成しました！issueボードを確認してください。 #{github_response["html_url"]}",
                    channel: data['item']['channel']
                }.to_json)
            end

        elsif  data['reaction'] == 'fish'
            slack_response = HTTP.post(SLACK_REACTION_URL, params: {
                    token: ENV['SLACK_API_TOKEN'],
                    channel: data['item']['channel'],
                    timestamp: data['item']['ts']
                })
            slack_response = JSON.parse(slack_response)

            ws.send({
                type: 'message',
                text: "魚のリアクションしましたね？",
                # text: "#{slack_response['message']['text']}に、魚のリアクションしましたね？",
                channel: data['item']['channel']
            }.to_json)
        elsif data['reaction'] == 'gyozabu'
            ws.send({
                type: 'message',
                text: "なるほど！<@#{data['user']}> さんは震えるほど餃子が食べたいみたいですよ！ <@here> 今日は、餃子活動しないんですか？",
                channel: data['item']['channel']
            }.to_json)
        end
    end
    ws.on :close do
        p [:close, event.code]
        ws = nil
        EN.stop
    end

end


