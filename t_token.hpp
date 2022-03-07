#ifndef __T_TOKEN_HPP_
#define __T_TOKEN_HPP_
#include <string>
class t_token {
	public:
	t_token();
	t_token(const t_token &t);
	std::string token_str;
	std::string comment;
	std::string get_format_comment();
	//  +演算子のオーバーロード
	t_token operator+(const t_token& t2);
};

#endif // __T_TOKEN_HPP_