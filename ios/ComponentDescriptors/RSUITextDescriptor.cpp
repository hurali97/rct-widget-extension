#include "RSUITextDescriptor.h"

void RSUITextProps::setProp(
                            const facebook::react::PropsParserContext &context,
                            facebook::react::RawPropsPropNameHash hash,
    const char *propName,
                            facebook::react::RawValue const &value) {
  BaseTextProps::setProp(context, hash, propName, value);
  Props::setProp(context, hash, propName, value);
}
