import asyncio

import os
from typing import AsyncGenerator, AsyncIterable, Awaitable, Optional, Tuple

from vocode.streaming.models.agent import AgentConfig, AgentType
from vocode.streaming.agent.base_agent import BaseAgent, RespondAgent

import logging
import os
from fastapi import FastAPI
from vocode.streaming.models.telephony import TwilioConfig
from pyngrok import ngrok
from vocode.streaming.telephony.config_manager.redis_config_manager import (
    RedisConfigManager,
)
from vocode.streaming.models.agent import ChatGPTAgentConfig
from vocode.streaming.models.message import BaseMessage
from vocode.streaming.models.synthesizer import ElevenLabsSynthesizerConfig
from vocode.streaming.telephony.server.base import (
    TwilioInboundCallConfig,
    TelephonyServer,
)

from vocode.streaming.telephony.server.base import TwilioCallConfig

import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from langchain.callbacks import AsyncIteratorCallbackHandler
from langchain.chat_models import ChatOpenAI
from langchain.schema import HumanMessage
from pydantic import BaseModel

import sys

# if running from python, this will load the local .env
# docker-compose will load the .env file by itself
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

config_manager = RedisConfigManager()

BASE_URL = os.getenv("BASE_URL")

if not BASE_URL:
    ngrok_auth = os.environ.get("NGROK_AUTH_TOKEN")
    if ngrok_auth is not None:
        ngrok.set_auth_token(ngrok_auth)
    port = sys.argv[sys.argv.index("--port") + 1] if "--port" in sys.argv else 6789

    # Open a ngrok tunnel to the dev server
    BASE_URL = ngrok.connect(port).public_url.replace("https://", "")
    logger.info('ngrok tunnel "{}" -> "http://127.0.0.1:{}"'.format(BASE_URL, port))

if not BASE_URL:
    raise ValueError("BASE_URL must be set in environment if not using pyngrok")

print(AgentType)

telephony_server = TelephonyServer(
    base_url=BASE_URL,
    config_manager=config_manager,
    inbound_call_configs=[
        TwilioInboundCallConfig(
            url="/inbound_call",
            agent_config=ChatGPTAgentConfig(
                initial_message=BaseMessage(text="Hey, are you doing alright lately? You haven't been hitting your usual numbers recently. I just wanted to check in and see if things were alright."),
                prompt_preamble="You should act as someone concered for the other participant in the conversation as they have not been performing as well on the mountain biking workouts as they may have been recently. Make sure to enquire about any possible injuries or events in their life that may be affecting them. Take their response and suggest possible remedies",
                #initial_message=BaseMessage(text="Hey, I have not been able to sleep properly because I am stressed cause of my upcoming exams, can i get an appointment please."),
                #prompt_preamble="You are simulating a phone call with a doctor. You are 'John Doe' to book a medical appointment to see a general physician on Wednesday. Your student id is 54329 and your date of birth is 2002-01-15 ",
                generate_responses=True,
                model_name="gpt-3.5-turbo"
            ),
            # agent_config=SpellerAgentConfig(generate_responses=False, initial_message=BaseMessage(text="What up.")),
            twilio_config=TwilioConfig(
                account_sid=os.environ["TWILIO_ACCOUNT_SID"],
                auth_token=os.environ["TWILIO_AUTH_TOKEN"],
                record=True
            ),
            synthesizer_config=ElevenLabsSynthesizerConfig.from_telephone_output_device(
            api_key=os.getenv("ELEVENLABS_API_KEY"),
            voice_id=os.getenv("YOUR VOICE ID")
        )
        )
    ],
    logger=logger,
)

import os
import sys
import typing
from dotenv import load_dotenv

from langchain.memory import ConversationBufferMemory
from langchain.agents import load_tools

from stdout_filterer import RedactPhoneNumbers

load_dotenv()

from langchain.chat_models import ChatOpenAI
# from langchain.chat_models import BedrockChat
from langchain.agents import initialize_agent
from langchain.agents import AgentType



class QueryItem(BaseModel):
    query: str

@app.post("/senpai")
def exec():
    print("woh")

app.include_router(telephony_server.get_router())