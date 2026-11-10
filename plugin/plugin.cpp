// Small QML plugin exposing the compositor effects MetroStart needs.
// KWindowEffects has no QML API, so the applet asks the compositor for a
// blur-behind region through this singleton.

#include <QObject>
#include <QQuickWindow>
#include <QRegion>
#include <QQmlEngine>
#include <QQmlExtensionPlugin>

#include <KWindowEffects>

class WindowEffects : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE void setBlurBehind(QQuickWindow *window, bool enable, int width, int height)
    {
        if (!window)
            return;
        QRegion region;
        if (enable && width > 0 && height > 0)
            region = QRegion(0, 0, width, height);
        KWindowEffects::enableBlurBehind(window, enable, region);
    }

    Q_INVOKABLE void setSlide(QQuickWindow *window, int edge, int offset)
    {
        if (!window)
            return;
        KWindowEffects::slideWindow(window, static_cast<KWindowEffects::SlideFromLocation>(edge), offset);
    }
};

class MetroStartEffectsPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterSingletonType<WindowEffects>(uri, 1, 0, "WindowEffects",
            [](QQmlEngine *, QJSEngine *) -> QObject * { return new WindowEffects; });
    }
};

#include "plugin.moc"
