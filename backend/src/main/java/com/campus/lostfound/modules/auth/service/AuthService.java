package com.campus.lostfound.modules.auth.service;

import com.campus.lostfound.modules.auth.dto.PasswordLoginReq;
import com.campus.lostfound.modules.auth.dto.RegisterReq;
import com.campus.lostfound.modules.auth.dto.ResetPasswordReq;
import com.campus.lostfound.modules.auth.dto.SmsLoginReq;
import com.campus.lostfound.modules.auth.dto.StudentLoginReq;
import com.campus.lostfound.modules.auth.dto.StudentRegisterReq;
import com.campus.lostfound.modules.auth.dto.TokenVO;

public interface AuthService {

    TokenVO register(RegisterReq req, String ip);

    TokenVO smsLogin(SmsLoginReq req, String ip);

    TokenVO passwordLogin(PasswordLoginReq req, String ip);

    TokenVO studentRegister(StudentRegisterReq req, String ip);

    TokenVO studentLogin(StudentLoginReq req, String ip);

    boolean isStudentNoTaken(String studentNo);

    TokenVO refresh(String refreshToken);

    void resetPassword(ResetPasswordReq req);

    void logout(Long userId);
}
