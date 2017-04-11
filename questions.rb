require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('aa_questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end

class User

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil if user.empty?
    User.new(user.first)
  end

class Question

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil if question.empty?
    Question.new(question.first)
  end

class QuestionFollow
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id
    questionfollow = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL
    return nil if questionfollow.empty?
    QuestionFollow.new(questionfollow.first)
  end

class Reply
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil if reply.empty?
    Reply.new(reply.first)
  end


class QuestionLike
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id
    questionlike = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    return nil if questionlike.empty?
    QuestionLike.new(questionlike.first)
  end
