#ifndef __T_TOKEN_HPP_
#define __T_TOKEN_HPP_
class t_token {
	public:
	t_token(){
		token_str = "";
		comment = "";
	}
	t_token(const t_token &t){
		token_str = t.token_str;
		comment = t.comment;
	}
	std::string token_str;
	std::string comment;
	std::string get_format_comment() {
		if(comment.empty()){
			return "";
		} else {
			return "note right\n"
					+ comment + "\n"
					+ "end note\n";
		}
	}
	//  +演算子のオーバーロード
	t_token operator+(const t_token& t2) {
		t_token ret;
		ret.token_str = this->token_str + t2.token_str;
		ret.comment = this->comment + t2.comment;
		return ret;
	}
};

#endif // __T_TOKEN_HPP_