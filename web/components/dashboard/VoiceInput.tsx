'use client'

import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'

// Add types for Web Speech API
declare global {
    interface Window {
        webkitSpeechRecognition: any
    }
}

export default function VoiceInput() {
    const [isListening, setIsListening] = useState(false)
    const [transcript, setTranscript] = useState('')
    const [isProcessing, setIsProcessing] = useState(false)
    const recognitionRef = useRef<any>(null)
    const router = useRouter()

    useEffect(() => {
        if (typeof window !== 'undefined' && window.webkitSpeechRecognition) {
            const recognition = new window.webkitSpeechRecognition()
            recognition.continuous = false
            recognition.interimResults = true
            recognition.lang = 'en-US'

            recognition.onstart = () => {
                setIsListening(true)
                setTranscript('')
            }

            recognition.onresult = (event: any) => {
                let currentTranscript = ''
                for (let i = event.resultIndex; i < event.results.length; i++) {
                    currentTranscript += event.results[i][0].transcript
                }
                setTranscript(currentTranscript)
            }

            recognition.onerror = (event: any) => {
                console.error('Speech recognition error', event.error)
                setIsListening(false)
            }

            recognition.onend = () => {
                setIsListening(false)
                if (transcriptRef.current.trim()) {
                    handleProcess(transcriptRef.current)
                }
            }

            recognitionRef.current = recognition
        }
    }, []) // Empty dependency array, we use refs for closures

    // Keep track of transcript in a ref to access it in onend listener without re-binding
    const transcriptRef = useRef('')
    useEffect(() => {
        transcriptRef.current = transcript
    }, [transcript])


    const toggleListening = () => {
        if (!recognitionRef.current) {
            alert('Your browser does not support speech recognition. Please use Chrome or Safari.')
            return
        }

        if (isListening) {
            recognitionRef.current.stop()
        } else {
            recognitionRef.current.start()
        }
    }

    const handleProcess = async (text: string) => {
        setIsProcessing(true)
        try {
            // Use the generic device_id for web testing
            const webDeviceId = 'web-client-' + (typeof localStorage !== 'undefined' ?
                (localStorage.getItem('noa_device_id') || Math.random().toString(36).substring(7)) : 'unknown')

            if (typeof localStorage !== 'undefined' && !localStorage.getItem('noa_device_id')) {
                localStorage.setItem('noa_device_id', webDeviceId)
            }

            const res = await fetch('/api/process', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    text,
                    device_id: webDeviceId
                })
            })

            if (res.ok) {
                router.refresh()
            }
        } catch (error) {
            console.error('Error processing command:', error)
        } finally {
            setIsProcessing(false)
            setTranscript('')
        }
    }

    return (
        <div className="flex flex-col gap-2">
            <button
                onClick={toggleListening}
                disabled={isProcessing}
                className={`w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg transition-colors ${isListening
                    ? 'bg-red-500/10 text-red-500 border border-red-500/20'
                    : 'bg-accent-light text-foreground hover:bg-hover'
                    }`}
            >
                {isListening ? (
                    <>
                        <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
                        <span className="text-sm font-medium">Listening...</span>
                    </>
                ) : isProcessing ? (
                    <span className="text-sm font-medium text-muted">Thinking...</span>
                ) : (
                    <>
                        <MicIcon className="w-4 h-4" />
                        <span className="text-sm font-medium">Fast Dictation</span>
                    </>
                )}
            </button>

            {/* Streaming Preview */}
            {isListening && transcript && (
                <div className="px-1">
                    <p className="text-xs text-muted truncate">{transcript}</p>
                </div>
            )}
        </div>
    )
}

function MicIcon({ className }: { className?: string }) {
    return (
        <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 18.75a6 6 0 006-6v-1.5m-6 7.5a6 6 0 01-6-6v-1.5m6 7.5v3.75m-3.75 0h7.5M12 15.75a3 3 0 01-3-3V4.5a3 3 0 116 0v8.25a3 3 0 01-3 3z" />
        </svg>
    )
}
