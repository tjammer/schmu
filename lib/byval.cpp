#include <caml/alloc.h>
#include <llvm/IR/IRBuilder.h>

using namespace llvm;

// Thank you, zig
extern "C"
{
  void LlvmAddByvalAttr(LLVMValueRef fn_ref, value ArgNo, LLVMTypeRef type_val)
  {
    Function*   func = unwrap<Function>(fn_ref);
    AttrBuilder attr_builder(func->getContext());
    Type*       llvm_type = unwrap<Type>(type_val);
    attr_builder.addByValAttr(llvm_type);
    func->addParamAttrs(static_cast<unsigned>((ArgNo >> 1) - 1), attr_builder);
  }
}
