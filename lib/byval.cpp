#include <caml/alloc.h>
#include <llvm/IR/IRBuilder.h>

using namespace llvm;

// Thank you, zig
extern "C"
{
  void LlvmAddByvalAttr(LLVMValueRef fn_ref, value ArgNo, LLVMTypeRef type_val)
  {
    Function*           func     = unwrap<Function>(fn_ref);
    const AttributeList attr_set = func->getAttributes();
    AttrBuilder         attr_builder;
    Type*               llvm_type = unwrap<Type>(type_val);
    attr_builder.addByValAttr(llvm_type);
    const AttributeList new_attr_set =
      attr_set.addAttributes(func->getContext(), (ArgNo >> 1), attr_builder);
    func->setAttributes(new_attr_set);
  }
}
