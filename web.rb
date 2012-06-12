#! /usr/bin/ruby

require "./rumino/rumino"
require "mysql"


conf = mergeJSONs( "./defaults.json", ARGV[0] )
raise "need mysql in config" if !conf["mysql"] 

my = MysqlWrapper.new(conf["mysql"])

my.query( "create table if not exists commits ( id bigint not null primary key auto_increment, username char(64), reponame char(128), private int, sha char(40), data blob, index(username), index(reponame), index(sha) )")

def my.saveCommit(username,reponame,sha,priv, data)
  
  res = query("select id from commits where sha=\"#{esc(sha)}\" ")
  if res and res.size>0 then 
    p "commit #{sha} exists"
    return
  end

  newid = insert( "commits", { "username"=>username, "reponame"=>reponame, "sha"=>sha, "private"=>priv, "data"=>data })
  return newid
end



web = MiniWeb.new()
web.configure(conf)
web.useGlobalTrapAndPidFile()
web.onPOST() do |req,res|

  STDERR.print "onPOST. req:#{req.to_s.size}\n"

  p req

  res.body = "ok thx!"
  jss = URI.unescape( req.body.gsub( /^payload=/,""))

  json = JSON.parse(jss)
  repo = json["repository"]
  reponame = repo["name"]
  owner = repo["owner"]
  username = owner["name"]
  private = repo["private"]

  # save commit info
  commits = json["commits"]
  commits.each do |cmt|
    sha = cmt["id"]
    my.saveCommit( username, reponame, sha, private, jss )
  end

  p "commits:", my.count("commits")
end


web.start()


  
