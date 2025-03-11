#pragma once

#include <JuceHeader.h>

//==============================================================================
/**
 * The default moonbase ui integration allows to set a company logo as a component, 
 * so you can define custom animations and behaviours.
 * 
 * You can change the ANIMATE_COMPANY_LOGO flag below to 1 to enable an example animation that makes the logo shiver.
*/

#define ANIMATE_COMPANY_LOGO 0

class CompanyLogo : public Component, 
                    private Timer
{
public:
    CompanyLogo ();

private:
    std::unique_ptr<Drawable> logo;
    void paint (Graphics& g) override;  
    
    void timerCallback () override;
    LinearSmoothedValue<float> jitterX { 0.f };
    LinearSmoothedValue<float> jitterY { 0.f };
    Random random;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (CompanyLogo)
};

//==============================================================================
/**
*/
class MainComponent  : public juce::AudioAppComponent, 
                       private Moonbase::JUCEClient::ActivationUI::Listener
{
public:
    //==============================================================================
    MainComponent();
    ~MainComponent() override;

private:
    //==============================================================================
    /*
        Moonbase API member

        This handy macro will declare and initialise the Moonbase Client API for you, 
        using your Projucer project's ProjectInfo::companyName, 
        ProjectInfo::projectName and ProjectInfo::versionString

        Using this macro expects, that:
        - you've defined the ProjectInfo fields in your Projucer project.
        - you've added a 'moonbase_api_config.json' file as Binary Source to your Projucer project.

        For other ways to initialise the Moonbase Client API, see the Macros.h file in the Moonbase JUCEClient module (moonbase_JUCEClient/Source/Macros.h) or visit the API source directly.

        It's important that this member is either public or you have to declare your AudioProcessorEditor subclass as friend class to this processor. 
    */
    //==============================================================================

    MOONBASE_DECLARE_LICENSING_USING_JUCE_PROJECTINFO;
    
    //==============================================================================
    /*
        After adding the Moonbase API member, you'll have to add implementations to
        the prepareToPlay and getNextAudioBlock methods, to make use of the Moonbase API. 
        See MainComponent.cpp implementation file.
    */
    //==============================================================================    
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate) override;
    void getNextAudioBlock (const juce::AudioSourceChannelInfo& bufferToFill) override;
    void releaseResources() override;

    //==============================================================================
    /*
        Moonbase Activation UI member

        This handy macro will declare and initialise the Moonbase Activation UI for you. 
        For this to work you have to declare a Moonbase API member in your AudioProcessor class, 
        called 'moonbaseClient'. 

        Once added, you'll only have to add the MOONBASE_RESIZE_ACTIVATION_UI to your AudioProcessorEditor::resized () method
        and you can call MOONBASE_SHOW_ACTIVATION_UI whenever you want to show the activation UI (e.g. when clicking a button)

        Activation UI visibility in relation to activation state is managed automatically - you can only SHOW the UI, 
        using this macro, never hide it, that's all managed internally.
    */
    //==============================================================================
        
        MOONBASE_DECLARE_AND_INIT_ACTIVATION_UI_SAME_PARENT;
        
        //==============================================================================
        // Optional listener implementation for activation UI visibility changes
        void onActivationUiVisibilityChanged () override;
    
    //==============================================================================
    
    TextButton showActivationUiButton { "Show Activation UI" };

    //==============================================================================
    void paint (juce::Graphics& g) override;
    void resized() override;


    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainComponent)
};
