import React, { useState } from "react"
import PropTypes from "prop-types"
import Answer from "./Answer"

function QuestionForm(props) {
  const [question, setQuestion] = useState(props.question);
  const [answer, setAnswer] = useState(props.answer);

  function handleSubmit(e) {
    e.preventDefault();

    // Read the form data
    const form = e.target;
    const formData = new FormData(form);

    fetch("/questions", {
      method: form.method,
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
    }).then((data) => {
      if (data.ok) {
        const result = data.json();
        return result
      }
      throw new Error("some kind of error, wish I knew");
    }).then((response) => {
      setAnswer(response.answer)
    })
  }

  function handleQuestionChange(event) {
    setQuestion(event.target.value);
  }

  return (
    <React.Fragment>
      <form method="post" onSubmit={handleSubmit}>
        <label>
          Ask a question: <textarea name="question" id="question" value={question} onChange={handleQuestionChange}></textarea>
        </label>

        <div className="buttons">
          <button type="submit" id="ask-button" style={{display: answer === undefined ? 'block' : 'none' }}>
            Ask question
          </button>
        </div>
      </form>

      <Answer answer={answer} setAnswer={setAnswer}/>
    </React.Fragment>
  );
}

QuestionForm.propTypes = {
  question: PropTypes.string,
  answer: PropTypes.string,
};
export default QuestionForm
