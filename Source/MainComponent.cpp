#include "MainComponent.h"

//==============================================================================
//==============================================================================
CompanyLogo::CompanyLogo ()
{
    logo = Drawable::createFromImageData (BinaryData::MoonbaseLogo_svg, 
                                          BinaryData::MoonbaseLogo_svgSize);

    #if ANIMATE_COMPANY_LOGO
        jitterX.reset (15);
        jitterY.reset (15);
        startTimerHz (30);
    #endif
}

void CompanyLogo::timerCallback () 
{
    // this is just a simple example of how to animate the logo... this particular code makes the logo shiver
    const auto jitterRange = 0.1f;
    jitterX.setTargetValue (jmap (random.nextFloat(), 0.f, 1.f, -jitterRange, jitterRange));
    jitterY.setTargetValue (jmap (random.nextFloat(), 0.f, 1.f, -jitterRange, jitterRange));
    repaint ();
}

void CompanyLogo::paint (Graphics& g)
{
    const auto width = getWidth ();
    const auto height = getHeight ();
    auto area = getLocalBounds().toFloat().reduced (height * 0.1f);
    
    #if ANIMATE_COMPANY_LOGO
        const auto currentJitterX = jitterX.getNextValue ();
        const auto currentJitterY = jitterY.getNextValue ();
        area = area.translated (width * currentJitterX, height * currentJitterY);
    #endif
    
    if (logo != nullptr)
        logo->drawWithin (g, area, RectanglePlacement::centred, 1.0f);
}

//==============================================================================
//==============================================================================
MainComponent::MainComponent()
{
    addAndMakeVisible (showActivationUiButton);
    showActivationUiButton.onClick = [&]()
    {
        /*
            Moonbase API member activation UI visibility

            Use this macro to show the activation UI on user interaction like the click of a button.
        */
        MOONBASE_SHOW_ACTIVATION_UI;
    };

    /*
        Moonbase Activation UI member initialization

        Use this pointer to initialize Moonbase Activation UI details.
    */
    jassert (activationUI != nullptr);
    if (activationUI != nullptr)
    {
        // There are a max of 2 lines of text on the welcome screen, define them here
        activationUI->setWelcomePageText ("Weightless", "License Management");

        // Set the spinner logo, this is the little icon inside the spinner, when waiting for web responses
        activationUI->setSpinnerLogo (Drawable::createFromImageData (BinaryData::MoonbaseLogo_svg, 
                                                                     BinaryData::MoonbaseLogo_svgSize));

        // Scale the spinner logo as required for your asset if needed. See Submodules/moonbase_JUCEClient/Assets/Source/SVG/OverlayAssets for ideal assets.
        // activationUI->setSpinnerLogoScale (0.5f);
        
        // Set the company logo, this is the logo that is displayed on the welcome screen and the activated info screen
        activationUI->setCompanyLogo (std::make_unique<CompanyLogo> ());

        // Scale the company logo as required for your asset if needed. 
        // activationUI->setCompanyLogoScale ((0.25f));
        
        // Scale the welcome button text as required - this is only needed if your app name is very long like "Moonbase App Demo"... default scale is 0.37 (37% height of button asset)
        activationUI->setWelcomeButtonTextScale (0.3f);

        activationUI->addListener (this);
       
    }

    setSize (800, 600);

    if (juce::RuntimePermissions::isRequired (juce::RuntimePermissions::recordAudio)
        && ! juce::RuntimePermissions::isGranted (juce::RuntimePermissions::recordAudio))
    {
        juce::RuntimePermissions::request (juce::RuntimePermissions::recordAudio,
                                           [&] (bool granted) { setAudioChannels (granted ? 2 : 0, 2); });
    }
    else
    {
        setAudioChannels (2, 2);
    }
}

MainComponent::~MainComponent()
{
    if (activationUI != nullptr)
        activationUI->removeListener (this);

    shutdownAudio();
}

//==============================================================================
void MainComponent::prepareToPlay (int samplesPerBlockExpected, double sampleRate)
{
    /*
        Moonbase API member audio initialization

        Use this macro to initialize the Moonbase API member for audio processing.
    */
    MOONBASE_PREPARE_TO_PLAY (sampleRate, samplesPerBlockExpected);
}

void MainComponent::getNextAudioBlock (const juce::AudioSourceChannelInfo& bufferToFill)
{
    bufferToFill.clearActiveBufferRegion();

    // -- > Your audio processing goes here < -- //

    /*
        Moonbase API member audio processing

        Use this macro to process audio with the Moonbase API member. 
        It's important, that this is the last call in the processBlock method.
        Having this post-process will ensure, that the audio cuts out periodically, 
        if the app is not authorized. 
    */
    
    if (auto* buffer = bufferToFill.buffer)
    {
        MOONBASE_PROCESS (*buffer);
    }
}

void MainComponent::releaseResources()
{

}

//==============================================================================
void MainComponent::onActivationUiVisibilityChanged (const Moonbase::JUCEClient::ActivationUI::Visibility& visibility)
{
    /*
        Moonbase Activation UI visibility changed

        Use this callback to react to changes in the activation UI visibility.
        
        This callback is "chatty" and will be called anytime *something* 
        on the backend happened, that could warrant a visibility change.
    */

    jassert (activationUI != nullptr);
    if (activationUI == nullptr)
        return;

   
    DBG (
        "Activation UI visibility changed.\n"
        << "        Is visible: " << String (visibility.isVisible  ? "true" : "false")  << "\n"
        << "   Must be visible: " << String (visibility.mustBeVisible ? "true" : "false")
    );
}

//==============================================================================
void MainComponent::paint (juce::Graphics& g)
{
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));
}

void MainComponent::resized()
{
    /*
        Moonbase Activation UI member resizing

        Use this macro to make sure the activation UI always fits your plugin/app window.
        
    */
    MOONBASE_RESIZE_ACTIVATION_UI;

    Rectangle<int> activationUiButtonArea (250, 30);
    activationUiButtonArea.setCentre (getLocalBounds ().getCentre ());
    showActivationUiButton.setBounds (activationUiButtonArea);
}
