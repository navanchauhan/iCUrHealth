import os
from dotenv import load_dotenv

load_dotenv()

from vocode.streaming.telephony.conversation.outbound_call import OutboundCall
from vocode.streaming.telephony.config_manager.redis_config_manager import (
    RedisConfigManager,
)
from vocode.streaming.models.telephony import TwilioConfig
from speller_agent import SpellerAgentConfig

from vocode.streaming.agent.chat_gpt_agent import ChatGPTAgent

from vocode.streaming.models.agent import ChatGPTAgentConfig
from vocode.streaming.models.message import BaseMessage
from vocode.streaming.models.synthesizer import ElevenLabsSynthesizerConfig, AzureSynthesizerConfig


BASE_URL = os.environ["BASE_URL"]


async def main():
    config_manager = RedisConfigManager()

    outbound_call = OutboundCall(
        base_url=BASE_URL,
        to_phone="+16199806687",
        from_phone="+18886854928",
        config_manager=config_manager,
        agent_config=ChatGPTAgentConfig(
            initial_message=BaseMessage(text="Hey, are you doing alright lately? You haven't been hitting your usual numbers recently. I just wanted to check in and see if things were alright."), 
            prompt_preamble="You should act as someone concered for the other participant in the conversation as they have not been performing as well at mountain biking as they may have been recently. Make sure to enquire about any possible injuries or events in their life that may be affecting them. Take their response and suggest possible remedies.", 
            generate_response=True,
            ),
        twilio_config=TwilioConfig(
            account_sid=os.environ["TWILIO_ACCOUNT_SID"],
            auth_token=os.environ["TWILIO_AUTH_TOKEN"],
            #record=True
        )#,
        #synthesizer_config=ElevenLabsSynthesizerConfig.from_telephone_output_device(
        #   api_key=os.getenv("ELEVENLABS_API_KEY"),
        #   voice_id=os.getenv("ELEVENLABS_VOICE_ID")
        #)
    )
    input("Press enter to start call...")
    await outbound_call.start()

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())