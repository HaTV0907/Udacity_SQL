CREATE TABLE users (
    user_id SERIAL NOT NULL UNIQUE,
    user_name VARCHAR(25) NOT NULL UNIQUE PRIMARY KEY,
    last_login TIMESTAMP,
    CONSTRAINT user_name_not_empty CHECK(LENGTH(TRIM(user_name))>0)
);
CREATE INDEX users_index ON users (user_id);

CREATE TABLE topics (
    topic_id SERIAL NOT NULL PRIMARY KEY,
    topic_name VARCHAR(30) NOT NULL,
    topic_description VARCHAR(500),
    user_id INT NOT NULL REFERENCES users(user_id),
    CONSTRAINT unique_topic_name UNIQUE (topic_name),
    CONSTRAINT topic_name_not_empty CHECK (LENGTH(TRIM(topic_name))>0)
);
CREATE INDEX topics_index ON topics (topic_id);

CREATE TABLE posts (
    post_id SERIAL NOT NULL UNIQUE PRIMARY KEY,
    post_title VARCHAR(100) NOT NULL,
    post_url VARCHAR(500),
    post_content TEXT,
    topic_id INTEGER  NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE,
    user_id INTEGER  NOT NULL REFERENCES users(user_id) ON DELETE SET NULL,
    created_time TIMESTAMP,
    CONSTRAINT post_title_not_empty CHECK (LENGTH(TRIM(post_title)) > 0),
    CONSTRAINT url_and_content_cons CHECK (
        (LENGTH(TRIM(post_url)) > 0 AND LENGTH(TRIM(post_content)) = 0) OR
        (LENGTH(TRIM(post_url)) = 0 AND LENGTH(TRIM(post_content)) > 0)
    )
);
CREATE INDEX posts_index ON posts(post_id);

CREATE TABLE comments (
    comment_id SERIAL NOT NULL UNIQUE PRIMARY KEY,
    comment_content TEXT NOT NULL,
    parent_id INT REFERENCES comments(comment_id) ON DELETE CASCADE,
    post_id INT NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE SET NULL,
    created_time TIMESTAMP,
    CONSTRAINT comment_content_not_empty CHECK (LENGTH(TRIM(comment_content)) > 0)
);
CREATE INDEX comments_index ON comments (comment_id);

CREATE TABLE votes (
    vote_id SERIAL NOT NULL UNIQUE PRIMARY KEY,
    up_vote INT,
    down_vote INT,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE SET NULL,
    post_id INT NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    CONSTRAINT vote_value CHECK ((up_vote = 1 AND down_vote IS NULL)
        OR (down_vote = - 1 AND up_vote IS NULL))
);
CREATE INDEX votes_index ON votes (vote_id);

/* DML Statements */
WITH user_data AS
(
  SELECT DISTINCT username
  FROM bad_posts
  UNION
  SELECT DISTINCT regexp_split_to_table(upvotes, ',')
  FROM bad_posts
  UNION
  SELECT DISTINCT regexp_split_to_table(downvotes, ',')
  FROM bad_posts
  UNION
  SELECT DISTINCT username
  FROM bad_comments
) 
INSERT INTO users (user_name)
SELECT username FROM user_data;

INSERT INTO topics (topic_name, user_id)
SELECT DISTINCT ON (bp.topic) bp.topic, u.user_id
FROM (
    SELECT DISTINCT topic, username
    FROM bad_posts
) AS bp
JOIN users AS u ON u.user_name = bp.username;

WITH post_data AS
(
    SELECT LEFT(bad_posts.title, 100)AS title, bad_posts.url, bad_posts.text_content, topics.topic_id, users.user_id
        FROM bad_posts
    JOIN topics ON bad_posts.topic = topics.topic_name
    JOIN users ON bad_posts.username = users.user_name
)
INSERT INTO posts (post_title, post_url, post_content, topic_id, user_id)
SELECT title, url, text_content, topic_id, user_id FROM post_data;

WITH comment_data AS
(
    SELECT bad_comments.text_content AS cmt_content, posts.post_id AS post_id, users.user_id AS user_id
        FROM bad_comments
    JOIN bad_posts 
        ON bad_comments.post_id = bad_posts.id
    JOIN posts
        ON posts.post_title = bad_posts.title
    JOIN users 
        ON bad_comments.username = users.user_name
)
INSERT INTO comments(comment_content, post_id, user_id)
SELECT cmt_content, post_id, user_id FROM comment_data;


WITH up_vote_data AS
(
    SELECT title title, regexp_split_to_table(upvotes, ',') user_name
    FROM bad_posts
)
INSERT INTO votes (up_vote, user_id, post_id)
    SELECT 1, users.user_id, posts.post_id
        FROM up_vote_data
    JOIN users
        ON  up_vote_data.user_name = users.user_name
    JOIN posts
        ON up_vote_data.title = posts.post_title;


WITH down_vote_data AS
(
    SELECT title title, regexp_split_to_table(downvotes, ',') user_name
    FROM bad_posts
)
INSERT INTO votes (down_vote, user_id, post_id)
    SELECT -1, users.user_id, posts.post_id
        FROM down_vote_data
    JOIN users
        ON down_vote_data.user_name = users.user_name
    JOIN posts
        ON down_vote_data.title = posts.post_title;
        
DROP TABLE bad_posts;
DROP TABLE bad_comments;
