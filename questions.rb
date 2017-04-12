require 'sqlite3'
require 'singleton'
require_relative 'model_base'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('aa_questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end


class User < ModelBase
  attr_accessor :id, :fname, :lname

  def initialize(options)
    super(options)
    @fname = options['fname']
    @lname = options['lname']
  end

  # def save
  #   if @id.nil?
  #     QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
  #       INSERT INTO
  #         users (fname, lname)
  #       VALUES
  #         (?, ?)
  #     SQL
  #
  #     @id = QuestionsDatabase.instance.last_insert_row_id
  #   else
  #     QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
  #       UPDATE
  #         users
  #       SET
  #         fname = ?, lname = ?
  #       WHERE
  #         id = ?
  #     SQL
  #   end
  # end

  # def self.all
  #   data = QuestionsDatabase.instance.execute("SELECT * FROM users")
  #   data.map { |datum| User.new(datum) }
  # end

  # def self.find_by_id(id)
  #   user = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       users
  #     WHERE
  #       id = ?
  #   SQL
  #   return nil if user.empty?
  #   User.new(user.first)
  # end

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

  def average_karma
    subresult = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        CAST(COUNT(DISTINCT(question_likes.user_id)) AS FLOAT) / COUNT(DISTINCT(questions.id)) AS avg_karma
      FROM
        questions
      LEFT JOIN
        question_likes ON question_likes.question_id = questions.id
      WHERE
        questions.user_id = ?
    SQL

    subresult.first['avg_karma']
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def authored_questions
    Question.find_by_user_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.find_by_user_id(@id)
  end
end

class Question < ModelBase
  attr_accessor :id, :user_id, :title, :body

  def initialize(options)
    super(options)
    @user_id = options['user_id']
    @title = options['title']
    @body = options['body']
  end

  # def self.all
  #   data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
  #   data.map { |datum| Question.new(datum) }
  # end



  # def self.find_by_id
  #   question = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       questions
  #     WHERE
  #       id = ?
  #   SQL
  #   return nil if question.empty?
  #   Question.new(question.first)
  # end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
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

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def save
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, @user_id, @title, @body)
        INSERT INTO
          users (user_id, title, body)
        VALUES
          (?, ?, ?)
      SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @user_id, @title, @body, @id)
        UPDATE
          users
        SET
          user_id = ?, title = ?, body = ?
        WHERE
          id = ?
      SQL
    end
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

  def followers
    QuestionFollow.find_by_question_id(@id)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
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

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_follows on questions.id = question_follows.question_id
      GROUP BY
        questions.id
      ORDER BY
        count(*) DESC
      LIMIT
        ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def self.find_by_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_follows ON questions.id = question_follows.question_id
      WHERE
        question_follows.user_id = ?
    SQL
    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end

  def self.find_by_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN
        question_follows ON users.id = question_follows.user_id
      WHERE
        question_follows.question_id = ?
    SQL
    return nil if followers.empty?
    followers.map { |follower| User.new(follower) }
  end

  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN
        question_follows ON question_follows.user_id = users.id
      WHERE
        question_id = ?
    SQL
    raise 'No followers' if followers.empty?
    followers.map { |follower| User.new(follower) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      WHERE
        question_follows.user_id = ?
    SQL
    raise 'No questions being followed' if questions.empty?
    questions.map { |question| Question.new(question) }
  end

end

class Reply < ModelBase
  attr_accessor :id, :user_id, :body, :question_id, :parent_id

  def initialize(options)
    super(options)
    @user_id = options['user_id']
    @body = options['body']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
  end

  def save
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, @user_id, @body, @question_id, @parent_id)
        INSERT INTO
          users (user_id, body, question_id, parent_id)
        VALUES
          (?, ?, ?, ?)
      SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @user_id, @body, @question_id, @parent_id, @id)
        UPDATE
          users
        SET
          user_id = ?, body = ?, question_id = ?, parent_id = ?
        WHERE
          id = ?
      SQL
    end
  end

  # def self.all
  #   data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
  #   data.map { |datum| Reply.new(datum) }
  # end

  # def self.find_by_id
  #   reply = QuestionsDatabase.instance.execute(<<-SQL, @id)
  #     SELECT
  #       *
  #     FROM
  #       replies
  #     WHERE
  #       id = ?
  #   SQL
  #   return nil if reply.empty?
  #   Reply.new(reply.first)
  # end

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

  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      users
    JOIN
      question_likes on question_likes.user_id = users.id
    WHERE
      question_likes.question_id = ?
    SQL
    raise 'No likers for this question' if likers.empty?
    likers.map { |liker| User.new(liker) }
  end

  def self.num_likes_for_question_id(question_id)
    subresult = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      count(*) as num_likes
    FROM
      users
    JOIN
      question_likes on question_likes.user_id = users.id
    WHERE
      question_likes.question_id = ?
    SQL
    subresult.first['num_likes']
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_likes ON question_likes.question_id = questions.id
      WHERE
        question_likes.user_id = ?
    SQL

    questions.map { |question| Question.new(question) }
  end

  def self.most_liked_questions(n)
    liked_questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_likes ON question_likes.question_id = questions.id
      GROUP BY
        question_likes.question_id
      ORDER BY
        count(*) DESC
      LIMIT
        ?
    SQL
    raise 'No questions were liked' if liked_questions.empty?
    liked_questions.map { |question| Question.new(question) }
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
