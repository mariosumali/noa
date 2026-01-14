import OpenAI from 'openai'

// OpenAI client instance
export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

// Process a text prompt and return AI response
export async function processPrompt(text: string): Promise<string> {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'system',
        content: `You are noa, a helpful personal AI assistant created by Mario Sumali. 
You help users with questions about their digital life - calendar, emails, files, and more.
Be concise, friendly, and helpful. Keep responses brief unless more detail is requested.`
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
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'system',
        content: `You are noa, a helpful personal AI assistant created by Mario Sumali.
You can see the user's screen and help them with questions about what's displayed.
Be concise, friendly, and helpful. Describe what you see accurately and answer their questions.`
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
              url: `data:image/png;base64,${screenshotBase64}`,
              detail: 'high'
            }
          }
        ]
      }
    ],
    max_tokens: 1000,
  })

  return completion.choices[0]?.message?.content || 'Sorry, I could not analyze the screen.'
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
