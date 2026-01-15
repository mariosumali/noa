import OpenAI from 'openai'

// OpenAI client instance
export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

// System prompt for noa
const SYSTEM_PROMPT = `You are noa, a helpful personal AI assistant created by Mario Sumali. 
You help users with questions about their digital life - calendar, emails, files, and more.
Be concise, friendly, and helpful. Keep responses brief unless more detail is requested.
When appropriate, use bullet points or short paragraphs for readability.`

const VISION_SYSTEM_PROMPT = `You are noa, a helpful personal AI assistant created by Mario Sumali.
You can see the user's screen and help them with questions about what's displayed.
Be concise, friendly, and helpful. Describe what you see accurately and answer their questions.
Focus on the most relevant parts of the screen for the user's question.`

const EMAIL_SYSTEM_PROMPT = `You are noa, a helpful personal AI assistant created by Mario Sumali.
You have access to the user's email and can help them manage their inbox.
Be concise, friendly, and helpful. Summarize emails clearly and highlight important information.
When listing emails, mention the sender, subject, and key points.
If asked about specific emails, provide relevant details from the context provided.`

// Process a text prompt and return AI response
export async function processPrompt(text: string): Promise<string> {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: SYSTEM_PROMPT
      },
      {
        role: 'user',
        content: text
      }
    ],
    max_tokens: 1000,
  })

  return completion.choices[0]?.message?.content || 'Sorry, I could not process that request.'
}

// Process a prompt with a screenshot for screen analysis
export async function processPromptWithScreen(text: string, screenshotBase64: string): Promise<string> {
  console.log('Processing with vision, image size:', Math.round(screenshotBase64.length / 1024), 'KB')

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'system',
        content: VISION_SYSTEM_PROMPT
      },
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text: text
          },
          {
            type: 'image_url',
            image_url: {
              url: `data:image/jpeg;base64,${screenshotBase64}`,
              detail: 'high'
            }
          }
        ]
      }
    ],
    max_tokens: 1500,
  })

  return completion.choices[0]?.message?.content || 'Sorry, I could not analyze the screen.'
}

// Process a prompt with additional context (emails, calendar, etc.)
export async function processPromptWithContext(text: string, context: string): Promise<string> {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: EMAIL_SYSTEM_PROMPT
      },
      {
        role: 'user',
        content: `Context from user's email:\n${context}\n\nUser's question: ${text}`
      }
    ],
    max_tokens: 1000,
  })

  return completion.choices[0]?.message?.content || 'Sorry, I could not process that request.'
}

// Transcribe audio using Whisper
export async function transcribeAudio(audioBuffer: Buffer): Promise<string> {
  const file = new File([audioBuffer], 'audio.webm', { type: 'audio/webm' })

  const transcription = await openai.audio.transcriptions.create({
    file: file,
    model: 'whisper-1',
  })

  return transcription.text
}
