#!/usr/bin/ruby
require "yaml"

class Node
    @map = {}
    @boundary = [] # ala Dijkstra
    def initialize(sha)
        @sha = sha
        @prevs = []
        @nexts = []
        @notes = []
    end
    def self.fromsha(sha)
        if @map.has_key? sha
            return @map[sha]
        else
            node = Node.new(sha)
            @boundary << node
            @map[sha] = node
            return node
        end
    end
    def self.explore
        while node = @boundary.pop
            node.explore
        end
    end
    def explore # TODO is there a better way of accessing parent commits in git?
        index = 1
        prevsha = `git rev-parse #{@sha}^#{index} 2> /dev/null`.strip
        while prevsha =~ /^[0-9a-f]{40}$/
            prev = Node.fromsha(prevsha)
            prev.addnext self
            @prevs << prev
            index = index + 1
            prevsha = `git rev-parse #{@sha}^#{index} 2> /dev/null`.strip
        end
    end
    def addnext(node)
        @nexts << node
    end
    def addnote(note)
        @notes << note
        return self
    end

=begin
    def self.collapse
        return @sources.map{|node| node.collapse}.flatten
    end
    def collapse(base = nil, count = 1)
        if @nexts.length == 1 and @prevs.length <= 1
            (@nexts[0]).collapse(base, count+1)
        else
            if base == nil
                newbase = `echo '#{count} commits #{@notes.join(', ')}' | git commit-tree #{@sha}^{tree}`.strip
            else
                newbase = `echo '#{count} commits #{@notes.join(', ')}' | git commit-tree #{@sha}^{tree} -p #{base}`.strip
            end
            if @nexts.length == 0
                return [newbase]
            else
                return @nexts.map{|node| node.collapse(newbase)}.flatten
            end
        end
    end
=end

    def collapse(force = false)
        if @lazy == nil
            @lazy = self.collaps(force)
        end
        return @lazy
    end
    def collaps(force = false)
        if @prevs.length > 1
            puts "echo 'Merge commit #{@notes.join(', ')}' | git commit-tree #{@sha}^{tree} #{self.collapse_helper(true)}"
            return {'count' => 0, 'sha' => `echo 'Merge commit #{@notes.join(', ')}' | git commit-tree #{@sha}^{tree} #{self.collapse_helper(true)}`.strip}
        end
        if @nexts.length == 1
            #puts @sha
            #puts YAML::dump self
            if @prevs.length == 0 # root commit (base case)
                return {'count' => 1, 'sha' => nil }
            elsif @prevs.length == 1 and @notes.length == 0 and not force
                collapsedparent = @prevs[0].collapse
                return {'count' => collapsedparent['count']+1, 'sha' => collapsedparent['sha']}
            end
        end
        return {'count' => 1, 'sha' => `echo '#{@prevs[0].collapse['count']} commits #{@notes.join(', ')}' | git commit-tree #{@sha}^{tree} #{self.collapse_helper}`.strip}
    end
    def collapse_helper(force = false)
        return @prevs.map do |node|
            sha = node.collapse(force)['sha']
            return sha ? "-p #{sha}" : ""
        end.join(' ')
    end

    def self.graph(branches = nil)
        if branches == nil
            branches = `git branch -a | cut -b3-`.each_line
        end
        headnodes = branches.map do |branch|
            Node.fromsha(`git rev-parse #{branch.strip}`.strip).addnote(branch.strip)
        end
        Node.explore
        puts `git log --color=always --pretty=format:'%s' --graph #{headnodes.map{|node| node.collapse(true)['sha']}.join(' ')}`
    end
end

Node.graph
