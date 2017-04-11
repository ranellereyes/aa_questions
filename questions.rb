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
  attr_accessor :id, :fname, :lname

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

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

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    User.new(user.first)
  end

  def authored_questions
    Question.find_by_user_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end
end

class Question
  attr_accessor :id, :user_id, :title, :body

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @title = options['title']
    @body = options['body']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
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

  def self.find_by_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL

    questions.map { |question| Question.new(question) }
  end

  def author
    user = QuestionsDatabase.instance.execute(<<-SQL, @user_id)
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL

    User.new(user.first)
  end

  def replies
    replies = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    replies.map { |reply| Reply.new(reply) }
  end
end

class QuestionFollow
  attr_accessor :id, :user_id, :question_id

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map { |datum| QuestionFollow.new(datum) }
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
end

class Reply
  attr_accessor :id, :user_id, :body, :question_id, :parent_id

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @body = options['body']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| Reply.new(datum) }
  end

  def self.find_by_id
    reply = QuestionsDatabase.instance.execute(<<-SQL, @id)
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

  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL

    replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    replies.map { |reply| Reply.new(reply) }
  end

  def author
    author = QuestionsDatabase.instance.execute(<<-SQL, @user_id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL

    User.new(author.first)
  end

  def question
    question = QuestionsDatabase.instance.execute(<<-SQL, @question_id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    Question.new(question.first)
  end

  def parent_reply
    parent_reply = QuestionsDatabase.instance.execute(<<-SQL, @parent_id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    raise 'No parent reply' if parent_reply.empty?
    Reply.new(parent_reply.first)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    raise 'No children' if children.empty?
    children.map { |child| Reply.new(child) }
  end

end

class QuestionLike
  attr_accessor :id, :user_id, :question_id

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |datum| QuestionLike.new(datum) }
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
end
