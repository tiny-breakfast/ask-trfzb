import React, { useRef, useState } from "react"
import PropTypes from "prop-types"
import Answer from "./Answer"

// magic number - perhaps just a short delay for suspense or
// something, or to let the audio start playing.
const ANSWER_SHOWER_DELAY = 1200

function QuestionForm(props) {
  const [question, setQuestion] = useState(props.question);
  const [questionId, setQuestionId] = useState(props.questionId);
  const questionIdRef = useRef(questionId);
  const [answer, setAnswer] = useState(props.answer);
  const [status, setStatus] = useState("waiting");
  const [answerShower, setAnswerShower] = useState(NaN);
  const questionTextareaRef = useRef(null);

  function handleSubmit(e) {
    e.preventDefault();

    if (document.getElementById("question").value == "") {
      alert("Please ask a question!");
      return false;
    }

    setStatus("asking")

    const form = e.target;
    const formData = new FormData(form);

    const csrfToken = document.querySelector('meta[name="csrf-token"]')

    fetch("/questions", {
      method: form.method,
      body: formData,
      headers: {
        "X-CSRF-Token": csrfToken && csrfToken.content,
      },
    }).then((data) => {
      if (data.ok) {
        const result = data.json();
        return result
      }
      throw new Error("some kind of error, wish I knew");
    }).then((response) => {
      setQuestionId(response.id)
      setStatus("answering")
      questionIdRef.current = response.id
      setAnswerShower(
        setTimeout(() => {
          showAnswer(response.answer, 0)
        }, ANSWER_SHOWER_DELAY)
      )
    })
  }

  function showAnswer(text, index) {
    if (index < text.length + 1) {
      const interval = randomInteger(30, 70);

      setAnswer(
        // this is probably not performant.
        //
        // not sure how to get a concatenative solution to work,
        // though.
        text.slice(0, index)
      )

      setAnswerShower(
        setTimeout(() => {
          showAnswer(text, index + 1)
        }, interval)
      )
    } else {
      history.pushState({}, null, "/questions/" + questionIdRef.current);
      setStatus("done")
    }
  }

  function randomInteger(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  function handleQuestionChange(event) {
    setQuestion(event.target.value);
  }

  function reset() {
    clearTimeout(answerShower)

    questionTextareaRef.current.focus()

    setAnswer(null)
    setStatus("waiting")

    history.pushState({}, null, "/");
  }

  function handleLuck(e) {
    const options = [
      'What is "the Real Frank Zappa Book" about?',
      "Who are the brain police?",
      "Does humor belong in music?",
    ]
    const random = ~~(Math.random() * options.length)

    setQuestion(options[random])
  }

  return (
    <React.Fragment>
      <form method="post" onSubmit={handleSubmit}>
        <label>
          Ask a question: <textarea name="question" id="question" value={question} onChange={handleQuestionChange} ref={questionTextareaRef}></textarea>
        </label>

        <div className="buttons" style={{display: answer === null ? '' : 'none' }}>
          <button type="submit" id="ask-button" disabled={ status === "waiting" ? "" : "disabled" }>
            { status === "asking" ? "Asking..." : "Ask question" }
          </button>

          <button id="lucky-button" style={{background: "#eee", borderColor: "#eee", color: "#444"}} disabled={ status === "asking" ? "disabled" : "" } onClick={handleLuck}>I'm feeling lucky</button>
        </div>
      </form>

      <Answer answer={answer} reset={reset} answering={status === "answering"}/>
    </React.Fragment>
  );
}

QuestionForm.propTypes = {
  question: PropTypes.string,
  answer: PropTypes.string,
  answerShower: PropTypes.number,
};
export default QuestionForm
